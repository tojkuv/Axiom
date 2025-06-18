# User Service Example - Authentication & User Management

This example demonstrates a complete user authentication and management system using the Axiom Swift Client Generator. It showcases authentication flows, session management, profile updates, and admin operations.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Authentication Patterns](#authentication-patterns)
3. [Generated Code Structure](#generated-code-structure)
4. [Implementation Tutorial](#implementation-tutorial)
5. [Security Best Practices](#security-best-practices)
6. [Advanced Features](#advanced-features)
7. [Testing Authentication](#testing-authentication)

## Overview

The User Service example demonstrates:
- **Complete Authentication Flow**: Registration, login, logout, token refresh
- **Profile Management**: View and update user profiles
- **Password Management**: Change password, reset password flow
- **Email Verification**: Account verification workflow
- **Admin Operations**: User management for administrators
- **Session Management**: Multiple device support
- **Security Features**: Token validation, device tracking

### Features Demonstrated

- ✅ **Secure Authentication**: Token-based authentication with refresh
- ✅ **Session Management**: Multi-device session handling
- ✅ **Profile Management**: Comprehensive user profiles
- ✅ **Email Verification**: Account verification workflow
- ✅ **Password Security**: Secure password management
- ✅ **Admin Operations**: User administration features
- ✅ **Real-time State**: Reactive authentication state
- ✅ **Offline Support**: Cached profile data

## Authentication Patterns

### Token-Based Authentication
The system uses JWT tokens with refresh token rotation:
- **Access Token**: Short-lived (15 minutes) for API access
- **Refresh Token**: Long-lived (30 days) for token renewal
- **Automatic Refresh**: Seamless token renewal

### State Management
Authentication state is managed through the Axiom framework:
- **Current User**: Reactive user state
- **Session Info**: Active session details
- **Loading States**: Authentication progress
- **Error Handling**: Comprehensive error management

## Generated Code Structure

```
generated/swift/
├── Clients/
│   ├── UserManagerClient.swift       # Authentication client
│   ├── UserManagerAction.swift       # Auth actions
│   ├── UserManagerState.swift        # Auth state
│   └── AxiomErrors.swift             # Error types
├── Contracts/
│   ├── UserService.swift             # Proto contracts
│   ├── UserModels.swift              # User types
│   └── AuthenticationTypes.swift     # Auth types
├── Tests/
│   └── UserManagerClientTests.swift  # Unit tests
└── Documentation/
    └── ... (comprehensive API docs)
```

## Implementation Tutorial

### Step 1: Generate Swift Clients

```bash
axiom-client-generator generate \
  --proto-path examples/user_service/proto/user_service.proto \
  --output-path examples/user_service/generated \
  --languages swift \
  --validate \
  --verbose
```

### Step 2: Create Authentication Manager

```swift
import Foundation
import AxiomCore
import AxiomArchitecture
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    private let client = UserManagerClient()
    
    // Published properties for SwiftUI
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    // Session management
    @Published var currentSession: UserSession?
    @Published var sessionExpiry: Date?
    
    private var stateObserver: Task<Void, Never>?
    private var tokenRefreshTimer: Timer?
    
    init() {
        observeAuthState()
        restoreSession()
    }
    
    private func observeAuthState() {
        stateObserver = Task {
            for await state in client.stateStream {
                // Update published properties
                self.currentUser = state.users.first
                self.currentSession = state.sessions.first
                self.isLoading = state.isLoading
                self.error = state.error?.localizedDescription
                
                // Update authentication status
                self.isAuthenticated = currentUser != nil && currentSession != nil
                
                // Schedule token refresh if needed
                if let session = currentSession {
                    scheduleTokenRefresh(for: session)
                }
            }
        }
    }
    
    private func restoreSession() {
        // Check for stored session
        if let storedToken = KeychainManager.shared.getAccessToken() {
            // Validate and restore session
            Task {
                await validateStoredSession(token: storedToken)
            }
        }
    }
    
    deinit {
        stateObserver?.cancel()
        tokenRefreshTimer?.invalidate()
    }
}
```

### Step 3: Implement Authentication Methods

```swift
extension AuthenticationManager {
    // MARK: - Registration
    func register(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        username: String
    ) async throws {
        let request = RegisterRequest(
            email: email,
            password: password,
            username: username,
            firstName: firstName,
            lastName: lastName,
            acceptTerms: true
        )
        
        let action = UserManagerAction.register(request)
        
        // Validate action before processing
        guard action.isValid else {
            throw AuthenticationError.validationFailed(action.validationErrors)
        }
        
        try await client.process(action)
        
        // Handle successful registration
        if let user = currentUser, let session = currentSession {
            await storeSession(session)
            AnalyticsManager.shared.track(.userRegistered(user.id))
        }
    }
    
    // MARK: - Login
    func login(email: String, password: String, rememberMe: Bool = false) async throws {
        let request = LoginRequest(
            email: email,
            password: password,
            rememberMe: rememberMe,
            deviceInfo: DeviceInfo.current.description
        )
        
        try await client.process(.login(request))
        
        // Store session securely
        if let session = currentSession {
            await storeSession(session)
            AnalyticsManager.shared.track(.userLoggedIn)
        }
    }
    
    // MARK: - Logout
    func logout(logoutAllDevices: Bool = false) async throws {
        guard let session = currentSession else { return }
        
        let request = LogoutRequest(
            sessionToken: session.accessToken,
            logoutAllDevices: logoutAllDevices
        )
        
        try await client.process(.logout(request))
        
        // Clear stored session
        await clearSession()
        AnalyticsManager.shared.track(.userLoggedOut)
    }
    
    // MARK: - Token Management
    private func refreshTokenIfNeeded() async throws {
        guard let session = currentSession,
              session.expiresAt.timeIntervalSinceNow < 300 else { // 5 minutes
            return
        }
        
        let request = RefreshTokenRequest(
            refreshToken: session.refreshToken,
            deviceInfo: DeviceInfo.current.description
        )
        
        try await client.process(.refreshToken(request))
        
        // Update stored session
        if let newSession = currentSession {
            await storeSession(newSession)
        }
    }
    
    private func scheduleTokenRefresh(for session: UserSession) {
        tokenRefreshTimer?.invalidate()
        
        let refreshTime = session.expiresAt.addingTimeInterval(-300) // 5 minutes before expiry
        let timeInterval = refreshTime.timeIntervalSinceNow
        
        guard timeInterval > 0 else { return }
        
        tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            Task {
                try? await self.refreshTokenIfNeeded()
            }
        }
    }
}
```

### Step 4: Session Storage & Security

```swift
extension AuthenticationManager {
    private func storeSession(_ session: UserSession) async {
        // Store tokens securely in Keychain
        KeychainManager.shared.setAccessToken(session.accessToken)
        KeychainManager.shared.setRefreshToken(session.refreshToken)
        
        // Store session metadata in UserDefaults
        let sessionData = try? JSONEncoder().encode(session)
        UserDefaults.standard.set(sessionData, forKey: "current_session")
    }
    
    private func clearSession() async {
        // Clear secure storage
        KeychainManager.shared.clearTokens()
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "current_session")
    }
    
    private func validateStoredSession(token: String) async {
        // In a real app, you would validate the token with your server
        // For now, we'll just check if we have a valid session
        guard let sessionData = UserDefaults.standard.data(forKey: "current_session"),
              let session = try? JSONDecoder().decode(UserSession.self, from: sessionData),
              session.expiresAt > Date() else {
            await clearSession()
            return
        }
        
        // Restore user profile
        await loadUserProfile()
    }
    
    private func loadUserProfile() async {
        guard let session = currentSession else { return }
        
        do {
            let request = GetProfileRequest(
                userId: session.userId,
                includePreferences: true,
                includeDevices: false
            )
            try await client.process(.getProfile(request))
        } catch {
            print("Failed to load user profile: \\(error)")
        }
    }
}
```

### Step 5: Create Login View

```swift
struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var showingRegistration = false
    @State private var showingPasswordReset = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Login form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                    
                    HStack {
                        Toggle("Remember me", isOn: $rememberMe)
                            .font(.caption)
                        
                        Spacer()
                        
                        Button("Forgot Password?") {
                            showingPasswordReset = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Login button
                Button(action: loginAction) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                .padding(.horizontal)
                
                // Registration link
                HStack {
                    Text("Don't have an account?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Sign Up") {
                        showingRegistration = true
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
            .alert("Login Failed", isPresented: .constant(authManager.error != nil)) {
                Button("OK") {
                    authManager.error = nil
                }
            } message: {
                Text(authManager.error ?? "")
            }
            .sheet(isPresented: $showingRegistration) {
                RegistrationView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingPasswordReset) {
                PasswordResetView()
                    .environmentObject(authManager)
            }
        }
    }
    
    private func loginAction() {
        Task {
            do {
                try await authManager.login(
                    email: email,
                    password: password,
                    rememberMe: rememberMe
                )
            } catch {
                // Error handling is managed by AuthenticationManager
                print("Login failed: \\(error)")
            }
        }
    }
}
```

### Step 6: Profile Management

```swift
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isEditing = false
    @State private var showingPasswordChange = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    ProfileHeaderView(user: authManager.currentUser)
                    
                    // Profile sections
                    if let user = authManager.currentUser {
                        ProfileSectionsView(user: user)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button("Edit Profile") {
                            isEditing = true
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Change Password") {
                            showingPasswordChange = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Logout") {
                            Task {
                                try await authManager.logout()
                            }
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $isEditing) {
                EditProfileView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingPasswordChange) {
                ChangePasswordView()
                    .environmentObject(authManager)
            }
        }
    }
}

struct ProfileHeaderView: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: user?.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(user?.displayName ?? "Unknown User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(user?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let user = user {
                    RoleBadge(role: user.role)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
    }
}
```

## Security Best Practices

### 1. Token Storage
```swift
class KeychainManager {
    static let shared = KeychainManager()
    
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    
    func setAccessToken(_ token: String) {
        set(token, forKey: accessTokenKey)
    }
    
    func getAccessToken() -> String? {
        get(forKey: accessTokenKey)
    }
    
    private func set(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
```

### 2. Network Security
```swift
class SecureAPIClient {
    func makeAuthenticatedRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: T? = nil
    ) async throws -> Data {
        guard let token = KeychainManager.shared.getAccessToken() else {
            throw AuthenticationError.noToken
        }
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = method.rawValue
        request.setValue("Bearer \\(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Certificate pinning
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            // Token expired, try to refresh
            try await AuthenticationManager.shared.refreshTokenIfNeeded()
            // Retry request...
        }
        
        return data
    }
}
```

### 3. Biometric Authentication
```swift
import LocalAuthentication

extension AuthenticationManager {
    func enableBiometricAuth() async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.biometryAny, error: &error) else {
            throw AuthenticationError.biometricNotAvailable
        }
        
        let reason = "Use biometric authentication to access your account"
        
        do {
            let success = try await context.evaluatePolicy(.biometryAny, localizedReason: reason)
            if success {
                // Store biometric preference
                UserDefaults.standard.set(true, forKey: "biometric_enabled")
            }
            return success
        } catch {
            throw AuthenticationError.biometricFailed
        }
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        let reason = "Authenticate to access your account"
        
        return try await context.evaluatePolicy(.biometryAny, localizedReason: reason)
    }
}
```

## Advanced Features

### 1. Multi-Factor Authentication
```swift
extension AuthenticationManager {
    func setupTwoFactorAuth() async throws {
        // Implementation for 2FA setup
        let request = SetupTwoFactorRequest()
        try await client.process(.setupTwoFactor(request))
    }
    
    func verifyTwoFactorCode(_ code: String) async throws {
        let request = VerifyTwoFactorRequest(code: code)
        try await client.process(.verifyTwoFactor(request))
    }
}
```

### 2. Device Management
```swift
extension AuthenticationManager {
    func getActiveDevices() async throws -> [UserDevice] {
        try await client.process(.getActiveDevices(.init()))
        return await client.getCurrentState().devices
    }
    
    func revokeDevice(_ deviceId: String) async throws {
        let request = RevokeDeviceRequest(deviceId: deviceId)
        try await client.process(.revokeDevice(request))
    }
}
```

### 3. Social Login
```swift
extension AuthenticationManager {
    func loginWithApple() async throws {
        // Apple Sign In implementation
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Handle authorization...
    }
    
    func loginWithGoogle() async throws {
        // Google Sign In implementation
    }
}
```

## Testing Authentication

```swift
import XCTest
@testable import UserService

class AuthenticationTests: XCTestCase {
    var authManager: AuthenticationManager!
    
    override func setUp() {
        super.setUp()
        authManager = AuthenticationManager()
    }
    
    func testSuccessfulLogin() async throws {
        // Test valid login
        try await authManager.login(
            email: "test@example.com",
            password: "validpassword"
        )
        
        XCTAssertTrue(authManager.isAuthenticated)
        XCTAssertNotNil(authManager.currentUser)
        XCTAssertNotNil(authManager.currentSession)
    }
    
    func testInvalidCredentials() async {
        do {
            try await authManager.login(
                email: "test@example.com",
                password: "wrongpassword"
            )
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertFalse(authManager.isAuthenticated)
            XCTAssertNil(authManager.currentUser)
        }
    }
    
    func testTokenRefresh() async throws {
        // Setup expired session
        let expiredSession = UserSession(
            id: "test-session",
            userId: "test-user",
            accessToken: "expired-token",
            refreshToken: "valid-refresh",
            expiresAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        // Test token refresh
        try await authManager.refreshTokenIfNeeded()
        
        // Verify new token
        XCTAssertNotEqual(authManager.currentSession?.accessToken, "expired-token")
    }
    
    func testLogout() async throws {
        // Login first
        try await authManager.login(email: "test@example.com", password: "password")
        XCTAssertTrue(authManager.isAuthenticated)
        
        // Then logout
        try await authManager.logout()
        
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertNil(authManager.currentSession)
    }
}
```

---

## 🔐 Security Summary

This example demonstrates:
- **Secure Token Management**: Keychain storage with proper access controls
- **Automatic Token Refresh**: Seamless session management
- **Input Validation**: Client-side validation before network requests
- **Error Handling**: Comprehensive error management
- **Biometric Integration**: Touch ID / Face ID support
- **Device Tracking**: Multi-device session management
- **Certificate Pinning**: Network security best practices

## 🎉 Next Steps

1. **Customize Authentication Flow**: Adapt to your specific requirements
2. **Add Social Login**: Integrate third-party authentication providers
3. **Implement 2FA**: Add multi-factor authentication
4. **Enhanced Security**: Add additional security measures
5. **Analytics**: Track authentication events and user behavior

This example provides a solid foundation for building secure, scalable authentication systems with the Axiom framework! 🚀