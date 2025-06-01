import Foundation
import Axiom

// MARK: - User Domain Client

/// Sophisticated user management client demonstrating advanced AxiomClient patterns
/// including authentication, session management, and complex business logic
actor UserClient: AxiomClient {
    
    // MARK: - AxiomClient Protocol
    
    typealias State = UserState
    typealias DomainModelType = UserDomain
    
    private(set) var stateSnapshot: UserState = UserState()
    let capabilities: CapabilityManager
    
    private var observers: [ComponentID: any AxiomContext] = [:]
    
    // MARK: - Advanced Client Features
    
    private let sessionManager: UserSessionManager
    private let authenticationService: AuthenticationService
    private let validationEngine: UserValidationEngine
    private let permissionManager: PermissionManager
    private let auditLogger: AuditLogger
    
    // Performance tracking
    private let performanceMonitor: PerformanceMonitor
    
    // MARK: - Initialization
    
    init(capabilities: CapabilityManager) {
        self.capabilities = capabilities
        self.performanceMonitor = PerformanceMonitor()
        self.sessionManager = UserSessionManager()
        self.authenticationService = AuthenticationService()
        self.validationEngine = UserValidationEngine()
        self.permissionManager = PermissionManager()
        self.auditLogger = AuditLogger()
    }
    
    // MARK: - AxiomClient Methods
    
    func initialize() async throws {
        // Validate required capabilities
        try await capabilities.validate(.userManagement)
        try await capabilities.validate(.authentication)
        try await capabilities.validate(.dataValidation)
        try await capabilities.validate(.sessionManagement)
        
        // Initialize subsystems
        await sessionManager.initialize()
        await authenticationService.initialize()
        await permissionManager.initialize()
        
        // Load persisted user state if available
        await loadPersistedState()
        
        await auditLogger.log("UserClient initialized", category: .systemEvent)
        print("🧑‍💼 UserClient initialized with sophisticated user management")
    }
    
    func shutdown() async {
        // Save current state
        await persistState()
        
        // Cleanup sessions
        await sessionManager.cleanup()
        
        // Clear observers
        observers.removeAll()
        
        await auditLogger.log("UserClient shutdown", category: .systemEvent)
        print("🧑‍💼 UserClient shutdown complete")
    }
    
    func updateState<T>(_ update: @Sendable (inout UserState) throws -> T) async rethrows -> T {
        let token = performanceMonitor.startOperation("updateState", category: .stateUpdate)
        defer {
            Task {
                await performanceMonitor.endOperation(token)
            }
        }
        
        let result = try update(&stateSnapshot)
        
        // Validate state after update
        stateSnapshot.validate()
        
        // Notify observers of state change
        await notifyObservers()
        
        return result
    }
    
    func validateState() async throws {
        let token = performanceMonitor.startOperation("validateState", category: .domainValidation)
        defer {
            Task {
                await performanceMonitor.endOperation(token)
            }
        }
        
        stateSnapshot.validate()
        
        if !stateSnapshot.isValid {
            let errors = stateSnapshot.validationErrors.map { $0.rawValue }.joined(separator: ", ")
            throw UserClientError.validationFailed(errors)
        }
        
        // Advanced validation through validation engine
        let validationResult = await validationEngine.validateUserState(stateSnapshot)
        if !validationResult.isValid {
            throw UserClientError.businessRuleViolation(validationResult.errors.joined(separator: ", "))
        }
    }
    
    func addObserver<T: AxiomContext>(_ context: T) async {
        let id = ComponentID.generate()
        observers[id] = context
        await auditLogger.log("Observer added: \(type(of: context))", category: .systemEvent)
    }
    
    func removeObserver<T: AxiomContext>(_ context: T) async {
        observers = observers.filter { _, observer in
            type(of: observer) != type(of: context)
        }
        await auditLogger.log("Observer removed: \(type(of: context))", category: .systemEvent)
    }
    
    func notifyObservers() async {
        for (_, observer) in observers {
            await observer.onClientStateChange(self)
        }
    }
    
    // MARK: - Authentication Operations
    
    func authenticateWithEmail(_ email: String, password: String) async throws -> AuthenticationResult {
        let token = performanceMonitor.startOperation("authenticateWithEmail", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(token, metadata: ["email": email])
            }
        }
        
        guard !stateSnapshot.isLocked else {
            await auditLogger.log("Authentication failed: account locked", category: .securityEvent)
            throw UserClientError.accountLocked
        }
        
        do {
            let authResult = try await authenticationService.authenticate(email: email, password: password)
            
            await updateState { state in
                state.authenticate(
                    method: .email,
                    token: authResult.token,
                    expiry: authResult.expiry
                )
                state.email = email
                state.id = authResult.userId
                state.calculateProfileCompleteness()
            }
            
            await sessionManager.createSession(userId: authResult.userId, token: authResult.token)
            await auditLogger.log("User authenticated successfully", category: .authenticationEvent)
            
            return authResult
            
        } catch {
            await updateState { state in
                state.recordLoginFailure()
            }
            
            await auditLogger.log("Authentication failed: \(error.localizedDescription)", category: .authenticationEvent)
            throw UserClientError.authenticationFailed(error.localizedDescription)
        }
    }
    
    func authenticateWithOAuth(provider: String, token: String) async throws -> AuthenticationResult {
        let perfToken = performanceMonitor.startOperation("authenticateWithOAuth", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(perfToken, metadata: ["provider": provider])
            }
        }
        
        let authResult = try await authenticationService.authenticateOAuth(provider: provider, token: token)
        
        await updateState { state in
            state.authenticate(
                method: .oauth,
                token: authResult.token,
                expiry: authResult.expiry
            )
            state.id = authResult.userId
            state.email = authResult.email ?? state.email
            state.displayName = authResult.displayName ?? state.displayName
            state.calculateProfileCompleteness()
        }
        
        await sessionManager.createSession(userId: authResult.userId, token: authResult.token)
        await auditLogger.log("OAuth authentication successful", category: .authenticationEvent)
        
        return authResult
    }
    
    func logout() async {
        let token = performanceMonitor.startOperation("logout", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(token)
            }
        }
        
        let userId = stateSnapshot.id
        
        await updateState { state in
            state.logout()
        }
        
        if let userId = userId {
            await sessionManager.destroySession(userId: userId)
        }
        
        await auditLogger.log("User logged out", category: .authenticationEvent)
    }
    
    // MARK: - Profile Management
    
    func updateProfile(displayName: String?, email: String?) async throws {
        let token = performanceMonitor.startOperation("updateProfile", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(token)
            }
        }
        
        guard stateSnapshot.canPerformAction(.editProfile) else {
            throw UserClientError.insufficientPermissions("Profile editing not allowed")
        }
        
        await updateState { state in
            state.updateProfile(displayName: displayName, email: email)
        }
        
        try await validateState()
        await persistState()
        
        await auditLogger.log("Profile updated", category: .userAction)
    }
    
    func updatePreferences(_ preferences: UserPreferences) async throws {
        let token = performanceMonitor.startOperation("updatePreferences", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(token)
            }
        }
        
        await updateState { state in
            state.updatePreferences(preferences)
        }
        
        await persistState()
        await auditLogger.log("User preferences updated", category: .userAction)
    }
    
    // MARK: - Permission Management
    
    func grantPermission(_ permission: UserPermission) async throws {
        let token = performanceMonitor.startOperation("grantPermission", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(token, metadata: ["permission": permission.rawValue])
            }
        }
        
        // Check if current user can grant permissions
        guard stateSnapshot.hasPermission(.userManagement) else {
            throw UserClientError.insufficientPermissions("Cannot grant permissions")
        }
        
        let canGrant = await permissionManager.canGrantPermission(permission, to: stateSnapshot.id)
        guard canGrant else {
            throw UserClientError.permissionDenied("Permission grant denied by system policy")
        }
        
        await updateState { state in
            state.addPermission(permission)
        }
        
        await auditLogger.log("Permission granted: \(permission.rawValue)", category: .permissionChange)
    }
    
    func revokePermission(_ permission: UserPermission) async throws {
        let token = performanceMonitor.startOperation("revokePermission", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(token, metadata: ["permission": permission.rawValue])
            }
        }
        
        guard stateSnapshot.hasPermission(.userManagement) else {
            throw UserClientError.insufficientPermissions("Cannot revoke permissions")
        }
        
        await updateState { state in
            state.removePermission(permission)
        }
        
        await auditLogger.log("Permission revoked: \(permission.rawValue)", category: .permissionChange)
    }
    
    // MARK: - Account Management
    
    func unlockAccount() async throws {
        let token = performanceMonitor.startOperation("unlockAccount", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(token)
            }
        }
        
        guard stateSnapshot.hasPermission(.userManagement) else {
            throw UserClientError.insufficientPermissions("Cannot unlock account")
        }
        
        await updateState { state in
            state.unlockAccount()
        }
        
        await auditLogger.log("Account unlocked", category: .securityEvent)
    }
    
    func deactivateAccount() async throws {
        let token = performanceMonitor.startOperation("deactivateAccount", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(token)
            }
        }
        
        guard stateSnapshot.canPerformAction(.deleteAccount) else {
            throw UserClientError.insufficientPermissions("Cannot deactivate account")
        }
        
        await updateState { state in
            state.accountStatus = .deactivated
            state.isAuthenticated = false
            state.sessionToken = nil
        }
        
        await sessionManager.destroyAllSessions()
        await auditLogger.log("Account deactivated", category: .userAction)
    }
    
    // MARK: - Session Management
    
    func refreshSession() async throws {
        let token = performanceMonitor.startOperation("refreshSession", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(token)
            }
        }
        
        guard let sessionToken = stateSnapshot.sessionToken,
              let userId = stateSnapshot.id else {
            throw UserClientError.noActiveSession
        }
        
        let newToken = try await sessionManager.refreshSession(userId: userId, currentToken: sessionToken)
        
        await updateState { state in
            state.sessionToken = newToken.token
            state.sessionExpiry = newToken.expiry
            state.lastActivity = Date()
        }
        
        await auditLogger.log("Session refreshed", category: .sessionEvent)
    }
    
    // MARK: - Analytics Integration
    
    func trackUserAction(_ action: UserAction, metadata: [String: Any] = [:]) async {
        let token = performanceMonitor.startOperation("trackUserAction", category: .businessLogic)
        defer {
            Task {
                await performanceMonitor.endOperation(token, metadata: ["action": "\(action)"])
            }
        }
        
        var trackingData = metadata
        trackingData["userId"] = stateSnapshot.id
        trackingData["sessionId"] = stateSnapshot.sessionToken
        trackingData["timestamp"] = Date().timeIntervalSince1970
        
        await auditLogger.log("User action: \(action)", category: .userAction, metadata: trackingData)
    }
    
    // MARK: - Performance Metrics
    
    func getPerformanceMetrics() async -> UserClientMetrics {
        let metrics = await performanceMonitor.getOverallMetrics()
        
        return UserClientMetrics(
            totalOperations: metrics.totalOperations,
            averageResponseTime: metrics.categoryMetrics[.businessLogic]?.averageDuration ?? 0,
            authenticationLatency: metrics.categoryMetrics[.businessLogic]?.averageDuration ?? 0,
            stateUpdateLatency: metrics.categoryMetrics[.stateUpdate]?.averageDuration ?? 0,
            validationLatency: metrics.categoryMetrics[.domainValidation]?.averageDuration ?? 0,
            activeObservers: observers.count,
            cacheHitRate: 0.95, // Would be calculated from actual cache metrics
            errorRate: 0.01 // Would be calculated from actual error tracking
        )
    }
    
    // MARK: - Private Methods
    
    private func loadPersistedState() async {
        // In a real implementation, would load from persistent storage
        // For demo purposes, simulate loading some default state
        await updateState { state in
            state.preferredLanguage = "en"
            state.timezone = TimeZone.current
            state.preferences = UserPreferences(theme: "dark", fontSize: 16.0, autoSave: true)
            state.permissions = [.profileRead, .profileWrite]
        }
    }
    
    private func persistState() async {
        // In a real implementation, would persist to storage
        // For demo purposes, just log the action
        await auditLogger.log("User state persisted", category: .systemEvent)
    }
}

// MARK: - Supporting Services

/// Advanced session management for user clients
private actor UserSessionManager {
    private var activeSessions: [String: SessionInfo] = [:]
    
    func initialize() async {
        // Initialize session tracking
    }
    
    func createSession(userId: String, token: String) async {
        let sessionInfo = SessionInfo(
            userId: userId,
            token: token,
            createdAt: Date(),
            lastActivity: Date(),
            isActive: true
        )
        activeSessions[userId] = sessionInfo
    }
    
    func refreshSession(userId: String, currentToken: String) async throws -> (token: String, expiry: Date) {
        guard activeSessions[userId]?.token == currentToken else {
            throw UserClientError.invalidSession
        }
        
        let newToken = UUID().uuidString
        let expiry = Date().addingTimeInterval(3600) // 1 hour
        
        activeSessions[userId]?.token = newToken
        activeSessions[userId]?.lastActivity = Date()
        
        return (token: newToken, expiry: expiry)
    }
    
    func destroySession(userId: String) async {
        activeSessions.removeValue(forKey: userId)
    }
    
    func destroyAllSessions() async {
        activeSessions.removeAll()
    }
    
    func cleanup() async {
        // Clean up expired sessions
        let now = Date()
        activeSessions = activeSessions.filter { _, session in
            now.timeIntervalSince(session.lastActivity) < 3600 // 1 hour timeout
        }
    }
}

/// Authentication service for various auth methods
private actor AuthenticationService {
    func initialize() async {
        // Initialize authentication systems
    }
    
    func authenticate(email: String, password: String) async throws -> AuthenticationResult {
        // Simulate authentication delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Simulate authentication logic
        if email.isEmpty || password.isEmpty {
            throw AuthenticationError.invalidCredentials
        }
        
        return AuthenticationResult(
            userId: UUID().uuidString,
            token: UUID().uuidString,
            expiry: Date().addingTimeInterval(3600),
            email: email,
            displayName: email.components(separatedBy: "@").first
        )
    }
    
    func authenticateOAuth(provider: String, token: String) async throws -> AuthenticationResult {
        // Simulate OAuth flow
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second
        
        return AuthenticationResult(
            userId: UUID().uuidString,
            token: UUID().uuidString,
            expiry: Date().addingTimeInterval(7200), // 2 hours for OAuth
            email: "user@\(provider).com",
            displayName: "OAuth User"
        )
    }
}

/// Advanced user state validation
private actor UserValidationEngine {
    func validateUserState(_ state: UserState) async -> ValidationResult {
        var errors: [String] = []
        
        // Business rule validations
        if state.isAuthenticated && state.accountStatus == .deleted {
            errors.append("Deleted account cannot be authenticated")
        }
        
        if state.permissions.contains(.userManagement) && state.accountStatus != .active {
            errors.append("User management permission requires active account")
        }
        
        if state.profileCompleteness < 0.5 && state.accountStatus == .active {
            errors.append("Active accounts must have at least 50% profile completion")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

/// Permission management system
private actor PermissionManager {
    private let systemPolicies: [UserPermission: PermissionPolicy] = [
        .userManagement: PermissionPolicy(requiresAdminApproval: true, minimumAccountAge: 30),
        .accountDelete: PermissionPolicy(requiresAdminApproval: false, minimumAccountAge: 7),
        .subscriptionManage: PermissionPolicy(requiresAdminApproval: false, minimumAccountAge: 1),
        .analyticsRead: PermissionPolicy(requiresAdminApproval: true, minimumAccountAge: 14),
        .profileRead: PermissionPolicy(requiresAdminApproval: false, minimumAccountAge: 0),
        .profileWrite: PermissionPolicy(requiresAdminApproval: false, minimumAccountAge: 0)
    ]
    
    func initialize() async {
        // Initialize permission system
    }
    
    func canGrantPermission(_ permission: UserPermission, to userId: String?) async -> Bool {
        guard let policy = systemPolicies[permission] else { return false }
        
        // For demo purposes, always allow unless admin approval required
        return !policy.requiresAdminApproval
    }
}

/// Audit logging for security and compliance
private actor AuditLogger {
    private var logs: [AuditLogEntry] = []
    
    func log(_ message: String, category: AuditCategory, metadata: [String: Any] = [:]) async {
        let entry = AuditLogEntry(
            timestamp: Date(),
            message: message,
            category: category,
            metadata: metadata
        )
        logs.append(entry)
        
        // In production, would send to logging service
        print("🔍 AUDIT: [\(category.rawValue)] \(message)")
    }
}

// MARK: - Supporting Types

public struct AuthenticationResult {
    public let userId: String
    public let token: String
    public let expiry: Date
    public let email: String?
    public let displayName: String?
}

private struct SessionInfo {
    let userId: String
    var token: String
    let createdAt: Date
    var lastActivity: Date
    var isActive: Bool
}

private struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}

private struct PermissionPolicy {
    let requiresAdminApproval: Bool
    let minimumAccountAge: Int // days
}

private struct AuditLogEntry {
    let timestamp: Date
    let message: String
    let category: AuditCategory
    let metadata: [String: Any]
}

private enum AuditCategory: String {
    case systemEvent = "system_event"
    case authenticationEvent = "authentication_event"
    case userAction = "user_action"
    case permissionChange = "permission_change"
    case securityEvent = "security_event"
    case sessionEvent = "session_event"
}

public struct UserClientMetrics {
    public let totalOperations: Int
    public let averageResponseTime: TimeInterval
    public let authenticationLatency: TimeInterval
    public let stateUpdateLatency: TimeInterval
    public let validationLatency: TimeInterval
    public let activeObservers: Int
    public let cacheHitRate: Double
    public let errorRate: Double
}

// MARK: - Error Types

public enum UserClientError: Error, LocalizedError {
    case validationFailed(String)
    case businessRuleViolation(String)
    case authenticationFailed(String)
    case accountLocked
    case insufficientPermissions(String)
    case permissionDenied(String)
    case noActiveSession
    case invalidSession
    
    public var errorDescription: String? {
        switch self {
        case .validationFailed(let details):
            return "User validation failed: \(details)"
        case .businessRuleViolation(let details):
            return "Business rule violation: \(details)"
        case .authenticationFailed(let details):
            return "Authentication failed: \(details)"
        case .accountLocked:
            return "Account is locked due to multiple failed login attempts"
        case .insufficientPermissions(let details):
            return "Insufficient permissions: \(details)"
        case .permissionDenied(let details):
            return "Permission denied: \(details)"
        case .noActiveSession:
            return "No active session found"
        case .invalidSession:
            return "Invalid or expired session"
        }
    }
}

public enum AuthenticationError: Error {
    case invalidCredentials
    case networkError
    case serviceUnavailable
}

// MARK: - User Domain Model

public struct UserDomain {
    // Domain-specific business rules and validation
    public static let maxLoginAttempts = 5
    public static let sessionTimeoutMinutes = 60
    public static let minimumPasswordLength = 8
    public static let profileCompletenessThreshold = 0.5
}