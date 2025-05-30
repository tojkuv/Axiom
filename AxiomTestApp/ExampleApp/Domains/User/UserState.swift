import Foundation
import Axiom

// MARK: - User Domain State

/// Sophisticated user state demonstrating complex state validation
/// and business rule compliance for comprehensive framework testing
public struct UserState: Sendable {
    
    // MARK: - Core User Data
    
    public var id: String?
    public var email: String
    public var displayName: String
    public var preferredLanguage: String
    public var timezone: TimeZone
    public var lastActivity: Date?
    
    // MARK: - Authentication State
    
    public var isAuthenticated: Bool
    public var authenticationMethod: AuthenticationMethod
    public var sessionToken: String?
    public var sessionExpiry: Date?
    public var failedLoginAttempts: Int
    public var isLocked: Bool
    
    // MARK: - User Preferences
    
    public var preferences: UserPreferences
    public var notificationSettings: NotificationSettings
    public var privacySettings: PrivacySettings
    
    // MARK: - Advanced State
    
    public var profileCompleteness: Double
    public var accountStatus: AccountStatus
    public var subscription: SubscriptionInfo?
    public var permissions: Set<UserPermission>
    public var metadata: [String: String]
    
    // MARK: - Validation State
    
    public var validationErrors: [ValidationError]
    public var isDirty: Bool
    public var lastValidation: Date?
    
    // MARK: - Initialization
    
    public init(
        id: String? = nil,
        email: String = "",
        displayName: String = "",
        preferredLanguage: String = "en",
        timezone: TimeZone = TimeZone.current,
        lastActivity: Date? = nil,
        isAuthenticated: Bool = false,
        authenticationMethod: AuthenticationMethod = .none,
        sessionToken: String? = nil,
        sessionExpiry: Date? = nil,
        failedLoginAttempts: Int = 0,
        isLocked: Bool = false,
        preferences: UserPreferences = UserPreferences(),
        notificationSettings: NotificationSettings = NotificationSettings(),
        privacySettings: PrivacySettings = PrivacySettings(),
        profileCompleteness: Double = 0.0,
        accountStatus: AccountStatus = .pending,
        subscription: SubscriptionInfo? = nil,
        permissions: Set<UserPermission> = [],
        metadata: [String: String] = [:],
        validationErrors: [ValidationError] = [],
        isDirty: Bool = false,
        lastValidation: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.preferredLanguage = preferredLanguage
        self.timezone = timezone
        self.lastActivity = lastActivity
        self.isAuthenticated = isAuthenticated
        self.authenticationMethod = authenticationMethod
        self.sessionToken = sessionToken
        self.sessionExpiry = sessionExpiry
        self.failedLoginAttempts = failedLoginAttempts
        self.isLocked = isLocked
        self.preferences = preferences
        self.notificationSettings = notificationSettings
        self.privacySettings = privacySettings
        self.profileCompleteness = profileCompleteness
        self.accountStatus = accountStatus
        self.subscription = subscription
        self.permissions = permissions
        self.metadata = metadata
        self.validationErrors = validationErrors
        self.isDirty = isDirty
        self.lastValidation = lastValidation
    }
    
    // MARK: - State Mutations
    
    public mutating func authenticate(method: AuthenticationMethod, token: String, expiry: Date) {
        isAuthenticated = true
        authenticationMethod = method
        sessionToken = token
        sessionExpiry = expiry
        failedLoginAttempts = 0
        isLocked = false
        lastActivity = Date()
        isDirty = true
    }
    
    public mutating func logout() {
        isAuthenticated = false
        authenticationMethod = .none
        sessionToken = nil
        sessionExpiry = nil
        lastActivity = Date()
        isDirty = true
    }
    
    public mutating func updateProfile(displayName: String?, email: String?) {
        if let displayName = displayName {
            self.displayName = displayName
        }
        if let email = email {
            self.email = email
        }
        calculateProfileCompleteness()
        isDirty = true
    }
    
    public mutating func updatePreferences(_ newPreferences: UserPreferences) {
        preferences = newPreferences
        isDirty = true
    }
    
    public mutating func recordLoginFailure() {
        failedLoginAttempts += 1
        if failedLoginAttempts >= 5 {
            isLocked = true
        }
        isDirty = true
    }
    
    public mutating func unlockAccount() {
        isLocked = false
        failedLoginAttempts = 0
        isDirty = true
    }
    
    public mutating func addPermission(_ permission: UserPermission) {
        permissions.insert(permission)
        isDirty = true
    }
    
    public mutating func removePermission(_ permission: UserPermission) {
        permissions.remove(permission)
        isDirty = true
    }
    
    public mutating func updateMetadata(key: String, value: String?) {
        if let value = value {
            metadata[key] = value
        } else {
            metadata.removeValue(forKey: key)
        }
        isDirty = true
    }
    
    // MARK: - Complex Business Logic
    
    public mutating func calculateProfileCompleteness() {
        var score = 0.0
        let totalFields = 8.0
        
        if !email.isEmpty { score += 1.0 }
        if !displayName.isEmpty { score += 1.0 }
        if id != nil { score += 1.0 }
        if isAuthenticated { score += 1.0 }
        if !preferences.isEmpty { score += 1.0 }
        if accountStatus == .active { score += 1.0 }
        if subscription != nil { score += 1.0 }
        if !permissions.isEmpty { score += 1.0 }
        
        profileCompleteness = score / totalFields
    }
    
    public func isSessionValid() -> Bool {
        guard isAuthenticated,
              let token = sessionToken,
              let expiry = sessionExpiry,
              !token.isEmpty else {
            return false
        }
        return Date() < expiry && !isLocked
    }
    
    public func hasPermission(_ permission: UserPermission) -> Bool {
        return permissions.contains(permission) && accountStatus == .active
    }
    
    public func canPerformAction(_ action: UserAction) -> Bool {
        guard isSessionValid() else { return false }
        
        switch action {
        case .viewProfile:
            return hasPermission(.profileRead)
        case .editProfile:
            return hasPermission(.profileWrite)
        case .deleteAccount:
            return hasPermission(.accountDelete)
        case .manageSubscription:
            return hasPermission(.subscriptionManage)
        case .accessAnalytics:
            return hasPermission(.analyticsRead)
        case .manageUsers:
            return hasPermission(.userManagement)
        }
    }
    
    // MARK: - Validation
    
    public mutating func validate() {
        validationErrors.removeAll()
        
        // Email validation
        if email.isEmpty {
            validationErrors.append(.missingEmail)
        } else if !isValidEmail(email) {
            validationErrors.append(.invalidEmailFormat)
        }
        
        // Display name validation
        if displayName.isEmpty {
            validationErrors.append(.missingDisplayName)
        } else if displayName.count < 2 {
            validationErrors.append(.displayNameTooShort)
        }
        
        // Authentication validation
        if isAuthenticated && sessionToken == nil {
            validationErrors.append(.missingSessionToken)
        }
        
        // Session expiry validation
        if isAuthenticated, let expiry = sessionExpiry, Date() > expiry {
            validationErrors.append(.sessionExpired)
        }
        
        // Account lock validation
        if isLocked && isAuthenticated {
            validationErrors.append(.accountLocked)
        }
        
        lastValidation = Date()
    }
    
    public var isValid: Bool {
        return validationErrors.isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - Supporting Types

public enum AuthenticationMethod: String, CaseIterable, Sendable {
    case none = "none"
    case email = "email"
    case oauth = "oauth"
    case biometric = "biometric"
    case twoFactor = "two_factor"
}

public enum AccountStatus: String, CaseIterable, Sendable {
    case pending = "pending"
    case active = "active"
    case suspended = "suspended"
    case deactivated = "deactivated"
    case deleted = "deleted"
}

public enum UserPermission: String, CaseIterable, Sendable {
    case profileRead = "profile_read"
    case profileWrite = "profile_write"
    case accountDelete = "account_delete"
    case subscriptionManage = "subscription_manage"
    case analyticsRead = "analytics_read"
    case userManagement = "user_management"
}

public enum UserAction: CaseIterable, Sendable {
    case viewProfile
    case editProfile
    case deleteAccount
    case manageSubscription
    case accessAnalytics
    case manageUsers
}

public enum ValidationError: String, CaseIterable, Sendable {
    case missingEmail = "missing_email"
    case invalidEmailFormat = "invalid_email_format"
    case missingDisplayName = "missing_display_name"
    case displayNameTooShort = "display_name_too_short"
    case missingSessionToken = "missing_session_token"
    case sessionExpired = "session_expired"
    case accountLocked = "account_locked"
}

public struct UserPreferences: Sendable {
    public var theme: String
    public var fontSize: Double
    public var autoSave: Bool
    public var compactMode: Bool
    public var customSettings: [String: String]
    
    public init(
        theme: String = "system",
        fontSize: Double = 16.0,
        autoSave: Bool = true,
        compactMode: Bool = false,
        customSettings: [String: String] = [:]
    ) {
        self.theme = theme
        self.fontSize = fontSize
        self.autoSave = autoSave
        self.compactMode = compactMode
        self.customSettings = customSettings
    }
    
    public var isEmpty: Bool {
        return theme == "system" && fontSize == 16.0 && !autoSave && !compactMode && customSettings.isEmpty
    }
}

public struct NotificationSettings: Sendable {
    public var emailNotifications: Bool
    public var pushNotifications: Bool
    public var analyticsAlerts: Bool
    public var marketingEmails: Bool
    public var quietHours: QuietHours?
    
    public init(
        emailNotifications: Bool = true,
        pushNotifications: Bool = true,
        analyticsAlerts: Bool = false,
        marketingEmails: Bool = false,
        quietHours: QuietHours? = nil
    ) {
        self.emailNotifications = emailNotifications
        self.pushNotifications = pushNotifications
        self.analyticsAlerts = analyticsAlerts
        self.marketingEmails = marketingEmails
        self.quietHours = quietHours
    }
}

public struct PrivacySettings: Sendable {
    public var dataCollection: Bool
    public var personalizedAds: Bool
    public var analyticsSharing: Bool
    public var thirdPartyIntegration: Bool
    
    public init(
        dataCollection: Bool = false,
        personalizedAds: Bool = false,
        analyticsSharing: Bool = false,
        thirdPartyIntegration: Bool = false
    ) {
        self.dataCollection = dataCollection
        self.personalizedAds = personalizedAds
        self.analyticsSharing = analyticsSharing
        self.thirdPartyIntegration = thirdPartyIntegration
    }
}

public struct QuietHours: Sendable {
    public let startTime: Date
    public let endTime: Date
    public let timezone: TimeZone
    
    public init(startTime: Date, endTime: Date, timezone: TimeZone = TimeZone.current) {
        self.startTime = startTime
        self.endTime = endTime
        self.timezone = timezone
    }
}

public struct SubscriptionInfo: Sendable {
    public let plan: String
    public let status: SubscriptionStatus
    public let startDate: Date
    public let nextBillingDate: Date?
    public let features: Set<String>
    
    public init(
        plan: String,
        status: SubscriptionStatus,
        startDate: Date,
        nextBillingDate: Date?,
        features: Set<String>
    ) {
        self.plan = plan
        self.status = status
        self.startDate = startDate
        self.nextBillingDate = nextBillingDate
        self.features = features
    }
}

public enum SubscriptionStatus: String, CaseIterable, Sendable {
    case active = "active"
    case paused = "paused"
    case cancelled = "cancelled"
    case expired = "expired"
}

// MARK: - Custom String Convertible

extension UserState: CustomStringConvertible {
    public var description: String {
        """
        User(id: \(id ?? "nil"), email: \(email), authenticated: \(isAuthenticated), status: \(accountStatus.rawValue), completeness: \(Int(profileCompleteness * 100))%)
        """
    }
}

extension UserState: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        UserState {
            id: \(id ?? "nil")
            email: \(email)
            displayName: \(displayName)
            isAuthenticated: \(isAuthenticated)
            authMethod: \(authenticationMethod.rawValue)
            sessionValid: \(isSessionValid())
            accountStatus: \(accountStatus.rawValue)
            permissions: \(permissions.map { $0.rawValue })
            profileCompleteness: \(Int(profileCompleteness * 100))%
            validationErrors: \(validationErrors.map { $0.rawValue })
            isDirty: \(isDirty)
        }
        """
    }
}