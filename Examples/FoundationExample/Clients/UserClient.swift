import Foundation
import Axiom

// MARK: - User Client

/// Domain client responsible for user management
/// Demonstrates domain client patterns with user authentication and management
@Capabilities([.storage, .businessLogic, .userDefaults, .analytics])
public actor UserClient: DomainClient {
    public typealias State = UserClientState
    public typealias DomainModelType = User
    
    // MARK: - State
    
    private var _state: State
    private var _stateVersion = StateVersion()
    private var observers: [WeakContextReference] = []
    
    public var stateSnapshot: State {
        _state
    }
    
    // MARK: - Initialization
    
    public init() async throws {
        self._state = UserClientState()
        
        // Initialize with sample data
        await loadSampleData()
    }
    
    // MARK: - State Management
    
    public func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
        let result = try update(&_state)
        _stateVersion = _stateVersion.incrementMinor()
        await notifyObservers()
        return result
    }
    
    public func validateState() async throws {
        for user in _state.users.values {
            let validation = user.validate()
            if !validation.isValid {
                throw DomainError.validationFailed(validation)
            }
        }
    }
    
    // MARK: - Domain Operations
    
    /// Creates a new user
    public func createUser(
        username: String,
        email: String,
        fullName: String,
        role: UserRole = .member
    ) async throws -> User {
        try capabilities.validate(.businessLogic)
        try capabilities.validate(.storage)
        
        // Check for existing username/email
        if _state.users.values.contains(where: { $0.username == username }) {
            throw DomainError.duplicateValue("Username '\\(username)' already exists")
        }
        
        if _state.users.values.contains(where: { $0.email == email }) {
            throw DomainError.duplicateValue("Email '\\(email)' already exists")
        }
        
        let user = User(
            username: username,
            email: email,
            fullName: fullName,
            role: role
        )
        
        // Validate before adding
        let validation = user.validate()
        guard validation.isValid else {
            throw DomainError.validationFailed(validation)
        }
        
        await updateState { state in
            state.users[user.id] = user
            state.metrics.totalUsers += 1
            state.lastUpdate = Date()
        }
        
        await trackAnalytics("user_created", metadata: [
            "role": role.rawValue,
            "username": username
        ])
        
        return user
    }
    
    /// Updates an existing user
    public func updateUser(_ userId: User.ID, with updates: UserUpdates) async throws -> User {
        try capabilities.validate(.businessLogic)
        try capabilities.validate(.storage)
        
        guard let existingUser = _state.users[userId] else {
            throw DomainError.notFound("User with id \\(userId) not found")
        }
        
        let updatedUser = try applyUpdates(to: existingUser, updates: updates)
        
        // Validate updated user
        let validation = updatedUser.validate()
        guard validation.isValid else {
            throw DomainError.validationFailed(validation)
        }
        
        await updateState { state in
            state.users[userId] = updatedUser
            state.lastUpdate = Date()
            
            // Update current user if applicable
            if userId == state.currentUserId {
                state.currentUser = updatedUser
            }
        }
        
        await trackAnalytics("user_updated", metadata: [
            "user_id": userId.description,
            "role": updatedUser.role.rawValue
        ])
        
        return updatedUser
    }
    
    /// Authenticates a user (simplified for demo)
    public func authenticateUser(username: String, password: String) async throws -> User {
        try capabilities.validate(.businessLogic)
        try capabilities.validate(.userDefaults)
        
        // In a real app, this would verify credentials properly
        guard let user = _state.users.values.first(where: { $0.username == username && $0.isActive }) else {
            throw DomainError.authenticationFailed("Invalid username or password")
        }
        
        await updateState { state in
            state.currentUserId = user.id
            state.currentUser = user
            state.lastLoginDate = Date()
        }
        
        await trackAnalytics("user_authenticated", metadata: [
            "user_id": user.id.description,
            "username": username
        ])
        
        return user
    }
    
    /// Logs out the current user
    public func logout() async {
        await updateState { state in
            state.currentUserId = nil
            state.currentUser = nil
        }
        
        await trackAnalytics("user_logged_out")
    }
    
    /// Gets current authenticated user
    public func getCurrentUser() async -> User? {
        _state.currentUser
    }
    
    /// Gets users with filtering
    public func getUsers(
        role: UserRole? = nil,
        isActive: Bool? = nil,
        searchTerm: String? = nil
    ) async -> [User] {
        var users = Array(_state.users.values)
        
        if let role = role {
            users = users.filter { $0.role == role }
        }
        
        if let isActive = isActive {
            users = users.filter { $0.isActive == isActive }
        }
        
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            let lowercasedTerm = searchTerm.lowercased()
            users = users.filter {
                $0.username.lowercased().contains(lowercasedTerm) ||
                $0.fullName.lowercased().contains(lowercasedTerm) ||
                $0.email.lowercased().contains(lowercasedTerm)
            }
        }
        
        return users.sorted { $0.fullName < $1.fullName }
    }
    
    /// Gets user by ID
    public func getUser(_ userId: User.ID) async -> User? {
        _state.users[userId]
    }
    
    /// Deactivates a user
    public func deactivateUser(_ userId: User.ID) async throws {
        try capabilities.validate(.businessLogic)
        
        guard let user = _state.users[userId] else {
            throw DomainError.notFound("User with id \\(userId) not found")
        }
        
        let deactivatedUser = try user.withUpdatedIsActive(false).get()
        
        await updateState { state in
            state.users[userId] = deactivatedUser
            state.metrics.activeUsers -= 1
            state.lastUpdate = Date()
            
            // Log out if current user
            if userId == state.currentUserId {
                state.currentUserId = nil
                state.currentUser = nil
            }
        }
        
        await trackAnalytics("user_deactivated", metadata: ["user_id": userId.description])
    }
    
    /// Gets user metrics
    public func getMetrics() async -> UserMetrics {
        _state.metrics
    }
    
    // MARK: - Observer Pattern
    
    public func addObserver<T: AxiomContext>(_ context: T) async {
        let reference = WeakContextReference(context)
        observers.append(reference)
        observers.removeAll { $0.context == nil }
    }
    
    public func removeObserver<T: AxiomContext>(_ context: T) async {
        observers.removeAll { $0.context === context as AnyObject }
    }
    
    public func notifyObservers() async {
        for observer in observers {
            if let context = observer.context {
                await context.onClientStateChange(self)
            }
        }
        observers.removeAll { $0.context == nil }
    }
    
    // MARK: - Lifecycle
    
    public func initialize() async throws {
        try await validateState()
    }
    
    public func shutdown() async {
        await updateState { state in
            state.users.removeAll()
            state.currentUser = nil
            state.currentUserId = nil
        }
        observers.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadSampleData() async {
        let sampleUsers = [
            User(
                username: "admin",
                email: "admin@taskmanager.com",
                fullName: "System Administrator",
                role: .admin
            ),
            User(
                username: "johndoe",
                email: "john.doe@taskmanager.com",
                fullName: "John Doe",
                role: .member
            ),
            User(
                username: "janesmith",
                email: "jane.smith@taskmanager.com",
                fullName: "Jane Smith",
                role: .manager
            )
        ]
        
        await updateState { state in
            for user in sampleUsers {
                state.users[user.id] = user
            }
            state.metrics.totalUsers = sampleUsers.count
            state.metrics.activeUsers = sampleUsers.count
        }
    }
    
    private func applyUpdates(to user: User, updates: UserUpdates) throws -> User {
        var updatedUser = user
        
        if let username = updates.username {
            updatedUser = try updatedUser.withUpdatedUsername(username).get()
        }
        
        if let email = updates.email {
            updatedUser = try updatedUser.withUpdatedEmail(email).get()
        }
        
        if let fullName = updates.fullName {
            updatedUser = try updatedUser.withUpdatedFullName(fullName).get()
        }
        
        if let role = updates.role {
            updatedUser = try updatedUser.withUpdatedRole(role).get()
        }
        
        if let isActive = updates.isActive {
            updatedUser = try updatedUser.withUpdatedIsActive(isActive).get()
        }
        
        // Update last active time
        updatedUser = try updatedUser.withUpdatedLastActiveAt(Date()).get()
        
        return updatedUser
    }
    
    private func trackAnalytics(_ event: String, metadata: [String: String] = [:]) async {
        await updateState { state in
            state.metrics.analyticsEvents += 1
        }
    }
}

// MARK: - Supporting Types

/// State managed by UserClient
public struct UserClientState: Sendable {
    public var users: [User.ID: User] = [:]
    public var currentUserId: User.ID?
    public var currentUser: User?
    public var lastLoginDate: Date?
    public var metrics: UserMetrics = UserMetrics()
    public var lastUpdate: Date = Date()
    
    public init() {}
}

/// Metrics for user management
public struct UserMetrics: Sendable {
    public var totalUsers: Int = 0
    public var activeUsers: Int = 0
    public var analyticsEvents: Int = 0
    
    public var inactiveUsers: Int {
        totalUsers - activeUsers
    }
    
    public init() {}
}

/// Updates that can be applied to a user
public struct UserUpdates {
    public let username: String?
    public let email: String?
    public let fullName: String?
    public let role: UserRole?
    public let isActive: Bool?
    
    public init(
        username: String? = nil,
        email: String? = nil,
        fullName: String? = nil,
        role: UserRole? = nil,
        isActive: Bool? = nil
    ) {
        self.username = username
        self.email = email
        self.fullName = fullName
        self.role = role
        self.isActive = isActive
    }
}

/// Domain error types
public enum DomainError: Error, AxiomError {
    case validationFailed(DomainValidationResult)
    case duplicateValue(String)
    case notFound(String)
    case authenticationFailed(String)
    
    public var category: ErrorCategory { .domain }
    public var severity: ErrorSeverity { .error }
    public var context: ErrorContext {
        ErrorContext(component: ComponentID("UserClient"), timestamp: Date(), additionalInfo: [:])
    }
    public var recoveryActions: [RecoveryAction] { [] }
    
    public var errorDescription: String? {
        switch self {
        case .validationFailed(let result):
            return "Validation failed: \\(result.errors.joined(separator: ", "))"
        case .duplicateValue(let message):
            return "Duplicate value: \\(message)"
        case .notFound(let message):
            return "Not found: \\(message)"
        case .authenticationFailed(let message):
            return "Authentication failed: \\(message)"
        }
    }
}

/// Weak reference to context for observer pattern
private struct WeakContextReference {
    weak var context: AnyObject?
    
    init<T: AxiomContext>(_ context: T) {
        self.context = context as AnyObject
    }
}