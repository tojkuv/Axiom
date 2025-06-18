import Foundation
import AuthenticationServices
import AxiomCore
import AxiomCapabilities

// MARK: - OAuth2 Capability Configuration

/// Configuration for OAuth2 capability
public struct OAuth2CapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let clientId: String
    public let clientSecret: String?
    public let authorizationEndpoint: URL
    public let tokenEndpoint: URL
    public let userInfoEndpoint: URL?
    public let revocationEndpoint: URL?
    public let discoveryEndpoint: URL?
    public let redirectURI: String
    public let scopes: Set<String>
    public let responseType: ResponseType
    public let grantType: GrantType
    public let codeChallenge: CodeChallengeMethod
    public let enablePKCE: Bool
    public let enableOpenIDConnect: Bool
    public let enableDiscovery: Bool
    public let enableTokenRefresh: Bool
    public let tokenRefreshThreshold: TimeInterval
    public let enableSecureStorage: Bool
    public let enableStateValidation: Bool
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let customParameters: [String: String]
    public let additionalHeaders: [String: String]
    public let timeout: TimeInterval
    public let maxRetries: Int
    
    public enum ResponseType: String, Codable, CaseIterable, Sendable {
        case code = "code"
        case token = "token"
        case idToken = "id_token"
        case codeIdToken = "code id_token"
        case codeToken = "code token"
        case idTokenToken = "id_token token"
        case codeIdTokenToken = "code id_token token"
    }
    
    public enum GrantType: String, Codable, CaseIterable, Sendable {
        case authorizationCode = "authorization_code"
        case implicit = "implicit"
        case resourceOwnerPasswordCredentials = "password"
        case clientCredentials = "client_credentials"
        case refreshToken = "refresh_token"
        case deviceCode = "urn:ietf:params:oauth:grant-type:device_code"
    }
    
    public enum CodeChallengeMethod: String, Codable, CaseIterable, Sendable {
        case plain = "plain"
        case S256 = "S256"
    }
    
    public init(
        clientId: String,
        clientSecret: String? = nil,
        authorizationEndpoint: URL,
        tokenEndpoint: URL,
        userInfoEndpoint: URL? = nil,
        revocationEndpoint: URL? = nil,
        discoveryEndpoint: URL? = nil,
        redirectURI: String,
        scopes: Set<String> = ["openid"],
        responseType: ResponseType = .code,
        grantType: GrantType = .authorizationCode,
        codeChallenge: CodeChallengeMethod = .S256,
        enablePKCE: Bool = true,
        enableOpenIDConnect: Bool = true,
        enableDiscovery: Bool = false,
        enableTokenRefresh: Bool = true,
        tokenRefreshThreshold: TimeInterval = 300.0, // 5 minutes before expiry
        enableSecureStorage: Bool = true,
        enableStateValidation: Bool = true,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        customParameters: [String: String] = [:],
        additionalHeaders: [String: String] = [:],
        timeout: TimeInterval = 30.0,
        maxRetries: Int = 3
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.userInfoEndpoint = userInfoEndpoint
        self.revocationEndpoint = revocationEndpoint
        self.discoveryEndpoint = discoveryEndpoint
        self.redirectURI = redirectURI
        self.scopes = scopes
        self.responseType = responseType
        self.grantType = grantType
        self.codeChallenge = codeChallenge
        self.enablePKCE = enablePKCE
        self.enableOpenIDConnect = enableOpenIDConnect
        self.enableDiscovery = enableDiscovery
        self.enableTokenRefresh = enableTokenRefresh
        self.tokenRefreshThreshold = tokenRefreshThreshold
        self.enableSecureStorage = enableSecureStorage
        self.enableStateValidation = enableStateValidation
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.customParameters = customParameters
        self.additionalHeaders = additionalHeaders
        self.timeout = timeout
        self.maxRetries = maxRetries
    }
    
    public var isValid: Bool {
        !clientId.isEmpty &&
        !redirectURI.isEmpty &&
        timeout > 0 &&
        maxRetries >= 0 &&
        tokenRefreshThreshold >= 0
    }
    
    public func merged(with other: OAuth2CapabilityConfiguration) -> OAuth2CapabilityConfiguration {
        OAuth2CapabilityConfiguration(
            clientId: other.clientId,
            clientSecret: other.clientSecret ?? clientSecret,
            authorizationEndpoint: other.authorizationEndpoint,
            tokenEndpoint: other.tokenEndpoint,
            userInfoEndpoint: other.userInfoEndpoint ?? userInfoEndpoint,
            revocationEndpoint: other.revocationEndpoint ?? revocationEndpoint,
            discoveryEndpoint: other.discoveryEndpoint ?? discoveryEndpoint,
            redirectURI: other.redirectURI,
            scopes: other.scopes.union(scopes),
            responseType: other.responseType,
            grantType: other.grantType,
            codeChallenge: other.codeChallenge,
            enablePKCE: other.enablePKCE,
            enableOpenIDConnect: other.enableOpenIDConnect,
            enableDiscovery: other.enableDiscovery,
            enableTokenRefresh: other.enableTokenRefresh,
            tokenRefreshThreshold: other.tokenRefreshThreshold,
            enableSecureStorage: other.enableSecureStorage,
            enableStateValidation: other.enableStateValidation,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            customParameters: customParameters.merging(other.customParameters) { _, new in new },
            additionalHeaders: additionalHeaders.merging(other.additionalHeaders) { _, new in new },
            timeout: other.timeout,
            maxRetries: other.maxRetries
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> OAuth2CapabilityConfiguration {
        var adjustedTimeout = timeout
        var adjustedLogging = enableLogging
        var adjustedRetries = maxRetries
        
        if environment.isLowPowerMode {
            adjustedTimeout *= 2.0
            adjustedRetries = min(maxRetries, 1)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return OAuth2CapabilityConfiguration(
            clientId: clientId,
            clientSecret: clientSecret,
            authorizationEndpoint: authorizationEndpoint,
            tokenEndpoint: tokenEndpoint,
            userInfoEndpoint: userInfoEndpoint,
            revocationEndpoint: revocationEndpoint,
            discoveryEndpoint: discoveryEndpoint,
            redirectURI: redirectURI,
            scopes: scopes,
            responseType: responseType,
            grantType: grantType,
            codeChallenge: codeChallenge,
            enablePKCE: enablePKCE,
            enableOpenIDConnect: enableOpenIDConnect,
            enableDiscovery: enableDiscovery,
            enableTokenRefresh: enableTokenRefresh,
            tokenRefreshThreshold: tokenRefreshThreshold,
            enableSecureStorage: enableSecureStorage,
            enableStateValidation: enableStateValidation,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            customParameters: customParameters,
            additionalHeaders: additionalHeaders,
            timeout: adjustedTimeout,
            maxRetries: adjustedRetries
        )
    }
}

// MARK: - OAuth2 Types

/// OAuth2 token response
public struct OAuth2Token: Codable, Sendable {
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: Int?
    public let refreshToken: String?
    public let scope: String?
    public let idToken: String?
    public let state: String?
    public let issuedAt: Date
    public let expiresAt: Date?
    
    // Custom coding keys to handle snake_case from OAuth2 servers
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
        case idToken = "id_token"
        case state
        case issuedAt = "issued_at"
        case expiresAt = "expires_at"
    }
    
    public init(
        accessToken: String,
        tokenType: String = "Bearer",
        expiresIn: Int? = nil,
        refreshToken: String? = nil,
        scope: String? = nil,
        idToken: String? = nil,
        state: String? = nil,
        issuedAt: Date = Date()
    ) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.scope = scope
        self.idToken = idToken
        self.state = state
        self.issuedAt = issuedAt
        
        if let expiresIn = expiresIn {
            self.expiresAt = issuedAt.addingTimeInterval(TimeInterval(expiresIn))
        } else {
            self.expiresAt = nil
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        tokenType = try container.decode(String.self, forKey: .tokenType)
        expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        scope = try container.decodeIfPresent(String.self, forKey: .scope)
        idToken = try container.decodeIfPresent(String.self, forKey: .idToken)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        
        if let issuedAtTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: .issuedAt) {
            issuedAt = Date(timeIntervalSince1970: issuedAtTimestamp)
        } else {
            issuedAt = Date()
        }
        
        if let expiresAtTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: .expiresAt) {
            expiresAt = Date(timeIntervalSince1970: expiresAtTimestamp)
        } else if let expiresIn = expiresIn {
            expiresAt = issuedAt.addingTimeInterval(TimeInterval(expiresIn))
        } else {
            expiresAt = nil
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(tokenType, forKey: .tokenType)
        try container.encodeIfPresent(expiresIn, forKey: .expiresIn)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try container.encodeIfPresent(scope, forKey: .scope)
        try container.encodeIfPresent(idToken, forKey: .idToken)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encode(issuedAt.timeIntervalSince1970, forKey: .issuedAt)
        try container.encodeIfPresent(expiresAt?.timeIntervalSince1970, forKey: .expiresAt)
    }
    
    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() >= expiresAt
    }
    
    public var willExpireSoon: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date().addingTimeInterval(300) >= expiresAt // 5 minutes threshold
    }
    
    public var authorizationHeader: String {
        "\(tokenType) \(accessToken)"
    }
}

/// OAuth2 user info response
public struct OAuth2UserInfo: Codable, Sendable {
    public let sub: String
    public let name: String?
    public let givenName: String?
    public let familyName: String?
    public let email: String?
    public let emailVerified: Bool?
    public let picture: String?
    public let locale: String?
    public let additionalClaims: [String: AnyCodable]?
    
    private enum CodingKeys: String, CodingKey {
        case sub, name, email, picture, locale
        case givenName = "given_name"
        case familyName = "family_name"
        case emailVerified = "email_verified"
    }
    
    public init(
        sub: String,
        name: String? = nil,
        givenName: String? = nil,
        familyName: String? = nil,
        email: String? = nil,
        emailVerified: Bool? = nil,
        picture: String? = nil,
        locale: String? = nil,
        additionalClaims: [String: AnyCodable]? = nil
    ) {
        self.sub = sub
        self.name = name
        self.givenName = givenName
        self.familyName = familyName
        self.email = email
        self.emailVerified = emailVerified
        self.picture = picture
        self.locale = locale
        self.additionalClaims = additionalClaims
    }
}

/// OAuth2 authentication state
public struct OAuth2AuthState: Sendable {
    public let state: String
    public let codeVerifier: String?
    public let codeChallenge: String?
    public let nonce: String?
    public let timestamp: Date
    
    public init(
        state: String = UUID().uuidString,
        codeVerifier: String? = nil,
        codeChallenge: String? = nil,
        nonce: String? = nil,
        timestamp: Date = Date()
    ) {
        self.state = state
        self.codeVerifier = codeVerifier
        self.codeChallenge = codeChallenge
        self.nonce = nonce
        self.timestamp = timestamp
    }
}

/// OAuth2 discovery document
public struct OAuth2DiscoveryDocument: Codable, Sendable {
    public let issuer: String
    public let authorizationEndpoint: URL
    public let tokenEndpoint: URL
    public let userInfoEndpoint: URL?
    public let jwksURI: URL?
    public let revocationEndpoint: URL?
    public let introspectionEndpoint: URL?
    public let responseTypesSupported: [String]?
    public let grantTypesSupported: [String]?
    public let scopesSupported: [String]?
    public let codeChallengeMethodsSupported: [String]?
    
    private enum CodingKeys: String, CodingKey {
        case issuer
        case authorizationEndpoint = "authorization_endpoint"
        case tokenEndpoint = "token_endpoint"
        case userInfoEndpoint = "userinfo_endpoint"
        case jwksURI = "jwks_uri"
        case revocationEndpoint = "revocation_endpoint"
        case introspectionEndpoint = "introspection_endpoint"
        case responseTypesSupported = "response_types_supported"
        case grantTypesSupported = "grant_types_supported"
        case scopesSupported = "scopes_supported"
        case codeChallengeMethodsSupported = "code_challenge_methods_supported"
    }
}

/// OAuth2 metrics
public struct OAuth2Metrics: Sendable {
    public let totalAuthentications: Int
    public let successfulAuthentications: Int
    public let failedAuthentications: Int
    public let tokenRefreshes: Int
    public let cacheHits: Int
    public let cacheMisses: Int
    public let averageAuthDuration: TimeInterval
    public let averageTokenRefreshDuration: TimeInterval
    
    public init(
        totalAuthentications: Int = 0,
        successfulAuthentications: Int = 0,
        failedAuthentications: Int = 0,
        tokenRefreshes: Int = 0,
        cacheHits: Int = 0,
        cacheMisses: Int = 0,
        averageAuthDuration: TimeInterval = 0,
        averageTokenRefreshDuration: TimeInterval = 0
    ) {
        self.totalAuthentications = totalAuthentications
        self.successfulAuthentications = successfulAuthentications
        self.failedAuthentications = failedAuthentications
        self.tokenRefreshes = tokenRefreshes
        self.cacheHits = cacheHits
        self.cacheMisses = cacheMisses
        self.averageAuthDuration = averageAuthDuration
        self.averageTokenRefreshDuration = averageTokenRefreshDuration
    }
    
    public var successRate: Double {
        guard totalAuthentications > 0 else { return 0.0 }
        return Double(successfulAuthentications) / Double(totalAuthentications)
    }
}

// MARK: - OAuth2 Resource

/// OAuth2 resource management
public actor OAuth2CapabilityResource: AxiomCapabilityResource {
    private let configuration: OAuth2CapabilityConfiguration
    private var httpClient: HTTPClientCapability?
    private var keychainCapability: KeychainCapability?
    private var currentToken: OAuth2Token?
    private var authenticationState: OAuth2AuthState?
    private var discoveryDocument: OAuth2DiscoveryDocument?
    private var metrics: OAuth2Metrics = OAuth2Metrics()
    private var authDurations: [TimeInterval] = []
    private var refreshDurations: [TimeInterval] = []
    
    public init(configuration: OAuth2CapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 10_000_000, // 10MB for token storage and HTTP operations
            cpu: 5.0, // 5% CPU for OAuth operations
            bandwidth: 1_000_000, // 1MB/s bandwidth
            storage: 1_000_000 // 1MB for secure token storage
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            return ResourceUsage(
                memory: currentToken != nil ? 500_000 : 100_000,
                cpu: httpClient != nil ? 2.0 : 0.1,
                bandwidth: 0, // Dynamic based on active operations
                storage: currentToken != nil ? 50_000 : 0
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        httpClient != nil
    }
    
    public func release() async {
        await httpClient?.deactivate()
        await keychainCapability?.deactivate()
        httpClient = nil
        keychainCapability = nil
        currentToken = nil
        authenticationState = nil
        discoveryDocument = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Create HTTP client for OAuth operations
        let httpConfig = HTTPClientCapabilityConfiguration(
            timeout: configuration.timeout,
            retryCount: configuration.maxRetries,
            enableLogging: configuration.enableLogging,
            enableMetrics: configuration.enableMetrics
        )
        
        httpClient = HTTPClientCapability(configuration: httpConfig)
        try await httpClient?.activate()
        
        // Create Keychain capability for secure storage if enabled
        if configuration.enableSecureStorage {
            let keychainConfig = KeychainCapabilityConfiguration(
                service: "com.axiom.oauth2",
                enableLogging: configuration.enableLogging
            )
            
            keychainCapability = KeychainCapability(configuration: keychainConfig)
            try await keychainCapability?.activate()
            
            // Try to load existing token from keychain
            await loadTokenFromKeychain()
        }
        
        // Perform discovery if enabled
        if configuration.enableDiscovery {
            try await performDiscovery()
        }
    }
    
    internal func updateConfiguration(_ configuration: OAuth2CapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - OAuth2 Operations
    
    public func createAuthorizationURL() async throws -> URL {
        let authState = OAuth2AuthState()
        authenticationState = authState
        
        var components = URLComponents(url: configuration.authorizationEndpoint, resolvingAgainstBaseURL: true)!
        
        var queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: configuration.responseType.rawValue),
            URLQueryItem(name: "scope", value: configuration.scopes.joined(separator: " "))
        ]
        
        if configuration.enableStateValidation {
            queryItems.append(URLQueryItem(name: "state", value: authState.state))
        }
        
        if configuration.enablePKCE && configuration.grantType == .authorizationCode {
            let codeVerifier = generateCodeVerifier()
            let codeChallenge = generateCodeChallenge(from: codeVerifier)
            
            authenticationState = OAuth2AuthState(
                state: authState.state,
                codeVerifier: codeVerifier,
                codeChallenge: codeChallenge
            )
            
            queryItems.append(URLQueryItem(name: "code_challenge", value: codeChallenge))
            queryItems.append(URLQueryItem(name: "code_challenge_method", value: configuration.codeChallenge.rawValue))
        }
        
        if configuration.enableOpenIDConnect {
            let nonce = generateNonce()
            authenticationState = OAuth2AuthState(
                state: authState.state,
                codeVerifier: authenticationState?.codeVerifier,
                codeChallenge: authenticationState?.codeChallenge,
                nonce: nonce
            )
            queryItems.append(URLQueryItem(name: "nonce", value: nonce))
        }
        
        // Add custom parameters
        for (key, value) in configuration.customParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw OAuth2Error.invalidAuthorizationURL
        }
        
        return url
    }
    
    public func handleAuthorizationResponse(_ url: URL) async throws -> OAuth2Token {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems ?? []
        
        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value
        }
        
        // Validate state if enabled
        if configuration.enableStateValidation {
            guard let receivedState = parameters["state"],
                  let expectedState = authenticationState?.state,
                  receivedState == expectedState else {
                throw OAuth2Error.invalidState
            }
        }
        
        // Check for error response
        if let error = parameters["error"] {
            let errorDescription = parameters["error_description"]
            throw OAuth2Error.authorizationFailed(error, errorDescription)
        }
        
        // Handle authorization code flow
        if let code = parameters["code"] {
            return try await exchangeCodeForToken(code)
        }
        
        // Handle implicit flow (access token directly in fragment)
        if let accessToken = parameters["access_token"] {
            let tokenType = parameters["token_type"] ?? "Bearer"
            let expiresIn = parameters["expires_in"].flatMap { Int($0) }
            let scope = parameters["scope"]
            let idToken = parameters["id_token"]
            let state = parameters["state"]
            
            let token = OAuth2Token(
                accessToken: accessToken,
                tokenType: tokenType,
                expiresIn: expiresIn,
                scope: scope,
                idToken: idToken,
                state: state
            )
            
            currentToken = token
            await saveTokenToKeychain(token)
            return token
        }
        
        throw OAuth2Error.invalidAuthorizationResponse
    }
    
    public func authenticateWithClientCredentials() async throws -> OAuth2Token {
        guard configuration.grantType == .clientCredentials else {
            throw OAuth2Error.unsupportedGrantType(configuration.grantType.rawValue)
        }
        
        guard let clientSecret = configuration.clientSecret else {
            throw OAuth2Error.missingClientSecret
        }
        
        let startTime = Date()
        
        var parameters = [
            "grant_type": configuration.grantType.rawValue,
            "client_id": configuration.clientId,
            "client_secret": clientSecret,
            "scope": configuration.scopes.joined(separator: " ")
        ]
        
        // Add custom parameters
        for (key, value) in configuration.customParameters {
            parameters[key] = value
        }
        
        let token = try await performTokenRequest(parameters: parameters)
        let duration = Date().timeIntervalSince(startTime)
        
        currentToken = token
        await saveTokenToKeychain(token)
        await updateAuthMetrics(duration: duration, success: true)
        
        return token
    }
    
    public func refreshToken() async throws -> OAuth2Token {
        guard configuration.enableTokenRefresh else {
            throw OAuth2Error.tokenRefreshNotEnabled
        }
        
        guard let currentToken = currentToken,
              let refreshToken = currentToken.refreshToken else {
            throw OAuth2Error.noRefreshToken
        }
        
        let startTime = Date()
        
        var parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": configuration.clientId
        ]
        
        if let clientSecret = configuration.clientSecret {
            parameters["client_secret"] = clientSecret
        }
        
        // Add custom parameters
        for (key, value) in configuration.customParameters {
            parameters[key] = value
        }
        
        let newToken = try await performTokenRequest(parameters: parameters)
        let duration = Date().timeIntervalSince(startTime)
        
        // Use refresh token from old token if not provided in response
        let finalToken: OAuth2Token
        if newToken.refreshToken == nil {
            finalToken = OAuth2Token(
                accessToken: newToken.accessToken,
                tokenType: newToken.tokenType,
                expiresIn: newToken.expiresIn,
                refreshToken: refreshToken, // Keep old refresh token
                scope: newToken.scope,
                idToken: newToken.idToken,
                state: newToken.state
            )
        } else {
            finalToken = newToken
        }
        
        self.currentToken = finalToken
        await saveTokenToKeychain(finalToken)
        await updateRefreshMetrics(duration: duration)
        
        return finalToken
    }
    
    public func getUserInfo() async throws -> OAuth2UserInfo {
        guard let userInfoEndpoint = configuration.userInfoEndpoint else {
            throw OAuth2Error.userInfoEndpointNotConfigured
        }
        
        guard let token = currentToken else {
            throw OAuth2Error.noAccessToken
        }
        
        guard let client = httpClient else {
            throw OAuth2Error.clientNotAvailable
        }
        
        var headers = configuration.additionalHeaders
        headers["Authorization"] = token.authorizationHeader
        headers["Accept"] = "application/json"
        
        let request = HTTPRequest(
            url: userInfoEndpoint,
            method: .GET,
            headers: headers,
            timeout: configuration.timeout
        )
        
        let response = try await client.execute(request)
        
        // Parse response
        let userInfo = try JSONDecoder().decode(OAuth2UserInfo.self, from: response.data)
        return userInfo
    }
    
    public func revokeToken() async throws {
        guard let revocationEndpoint = configuration.revocationEndpoint else {
            throw OAuth2Error.revocationEndpointNotConfigured
        }
        
        guard let token = currentToken else {
            throw OAuth2Error.noAccessToken
        }
        
        guard let client = httpClient else {
            throw OAuth2Error.clientNotAvailable
        }
        
        var parameters = [
            "token": token.accessToken,
            "client_id": configuration.clientId
        ]
        
        if let clientSecret = configuration.clientSecret {
            parameters["client_secret"] = clientSecret
        }
        
        let bodyData = parameters.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)!
        
        var headers = configuration.additionalHeaders
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        
        let request = HTTPRequest(
            url: revocationEndpoint,
            method: .POST,
            headers: headers,
            body: bodyData,
            timeout: configuration.timeout
        )
        
        _ = try await client.execute(request)
        
        // Clear current token
        currentToken = nil
        await clearTokenFromKeychain()
    }
    
    public func getCurrentToken() -> OAuth2Token? {
        currentToken
    }
    
    public func isAuthenticated() -> Bool {
        guard let token = currentToken else { return false }
        return !token.isExpired
    }
    
    public func willTokenExpireSoon() -> Bool {
        currentToken?.willExpireSoon ?? false
    }
    
    public func getMetrics() -> OAuth2Metrics {
        metrics
    }
    
    // MARK: - Private Implementation
    
    private func exchangeCodeForToken(_ code: String) async throws -> OAuth2Token {
        let startTime = Date()
        
        var parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": configuration.redirectURI,
            "client_id": configuration.clientId
        ]
        
        if let clientSecret = configuration.clientSecret {
            parameters["client_secret"] = clientSecret
        }
        
        if let codeVerifier = authenticationState?.codeVerifier {
            parameters["code_verifier"] = codeVerifier
        }
        
        // Add custom parameters
        for (key, value) in configuration.customParameters {
            parameters[key] = value
        }
        
        let token = try await performTokenRequest(parameters: parameters)
        let duration = Date().timeIntervalSince(startTime)
        
        currentToken = token
        await saveTokenToKeychain(token)
        await updateAuthMetrics(duration: duration, success: true)
        
        return token
    }
    
    private func performTokenRequest(parameters: [String: String]) async throws -> OAuth2Token {
        guard let client = httpClient else {
            throw OAuth2Error.clientNotAvailable
        }
        
        let bodyData = parameters.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)!
        
        var headers = configuration.additionalHeaders
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Accept"] = "application/json"
        
        let request = HTTPRequest(
            url: configuration.tokenEndpoint,
            method: .POST,
            headers: headers,
            body: bodyData,
            timeout: configuration.timeout
        )
        
        let response = try await client.execute(request)
        
        // Handle error responses
        if response.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(OAuth2ErrorResponse.self, from: response.data) {
                throw OAuth2Error.tokenRequestFailed(errorResponse.error, errorResponse.errorDescription)
            } else {
                throw OAuth2Error.tokenRequestFailed("http_error", "HTTP \(response.statusCode)")
            }
        }
        
        // Parse token response
        let token = try JSONDecoder().decode(OAuth2Token.self, from: response.data)
        return token
    }
    
    private func performDiscovery() async throws {
        guard let discoveryEndpoint = configuration.discoveryEndpoint else { return }
        
        guard let client = httpClient else {
            throw OAuth2Error.clientNotAvailable
        }
        
        let request = HTTPRequest(
            url: discoveryEndpoint,
            method: .GET,
            headers: ["Accept": "application/json"],
            timeout: configuration.timeout
        )
        
        let response = try await client.execute(request)
        let document = try JSONDecoder().decode(OAuth2DiscoveryDocument.self, from: response.data)
        discoveryDocument = document
    }
    
    private func generateCodeVerifier() -> String {
        // Generate a cryptographically secure random string
        var data = Data(count: 32)
        _ = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        return data.base64URLEncodedString()
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        switch configuration.codeChallenge {
        case .plain:
            return verifier
        case .S256:
            let data = verifier.data(using: .utf8)!
            let hash = SHA256.hash(data: data)
            return Data(hash).base64URLEncodedString()
        }
    }
    
    private func generateNonce() -> String {
        return UUID().uuidString
    }
    
    private func saveTokenToKeychain(_ token: OAuth2Token) async {
        guard configuration.enableSecureStorage,
              let keychain = keychainCapability else { return }
        
        do {
            let tokenData = try JSONEncoder().encode(token)
            let key = "oauth2_token_\(configuration.clientId)"
            try await keychain.store(key: key, data: tokenData)
        } catch {
            if configuration.enableLogging {
                print("[OAuth2] Failed to save token to keychain: \(error)")
            }
        }
    }
    
    private func loadTokenFromKeychain() async {
        guard configuration.enableSecureStorage,
              let keychain = keychainCapability else { return }
        
        do {
            let key = "oauth2_token_\(configuration.clientId)"
            let tokenData = try await keychain.retrieve(key: key)
            let token = try JSONDecoder().decode(OAuth2Token.self, from: tokenData)
            
            // Only use token if it's not expired
            if !token.isExpired {
                currentToken = token
            } else {
                // Remove expired token
                await clearTokenFromKeychain()
            }
        } catch {
            // Token not found or invalid, which is fine
        }
    }
    
    private func clearTokenFromKeychain() async {
        guard configuration.enableSecureStorage,
              let keychain = keychainCapability else { return }
        
        do {
            let key = "oauth2_token_\(configuration.clientId)"
            try await keychain.delete(key: key)
        } catch {
            // Error deleting is fine
        }
    }
    
    private func updateAuthMetrics(duration: TimeInterval, success: Bool) async {
        authDurations.append(duration)
        
        let averageDuration = authDurations.reduce(0, +) / Double(authDurations.count)
        
        metrics = OAuth2Metrics(
            totalAuthentications: metrics.totalAuthentications + 1,
            successfulAuthentications: success ? metrics.successfulAuthentications + 1 : metrics.successfulAuthentications,
            failedAuthentications: success ? metrics.failedAuthentications : metrics.failedAuthentications + 1,
            tokenRefreshes: metrics.tokenRefreshes,
            cacheHits: metrics.cacheHits,
            cacheMisses: metrics.cacheMisses,
            averageAuthDuration: averageDuration,
            averageTokenRefreshDuration: metrics.averageTokenRefreshDuration
        )
    }
    
    private func updateRefreshMetrics(duration: TimeInterval) async {
        refreshDurations.append(duration)
        
        let averageDuration = refreshDurations.reduce(0, +) / Double(refreshDurations.count)
        
        metrics = OAuth2Metrics(
            totalAuthentications: metrics.totalAuthentications,
            successfulAuthentications: metrics.successfulAuthentications,
            failedAuthentications: metrics.failedAuthentications,
            tokenRefreshes: metrics.tokenRefreshes + 1,
            cacheHits: metrics.cacheHits,
            cacheMisses: metrics.cacheMisses,
            averageAuthDuration: metrics.averageAuthDuration,
            averageTokenRefreshDuration: averageDuration
        )
    }
}

// MARK: - OAuth2 Error Response

/// OAuth2 error response structure
internal struct OAuth2ErrorResponse: Codable {
    let error: String
    let errorDescription: String?
    let errorURI: String?
    
    private enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case errorURI = "error_uri"
    }
}

// MARK: - OAuth2 Capability Implementation

/// OAuth2 capability providing OAuth 2.0 / OpenID Connect authentication
public actor OAuth2Capability: ExternalServiceCapability {
    public typealias ConfigurationType = OAuth2CapabilityConfiguration
    public typealias ResourceType = OAuth2CapabilityResource
    
    private var _configuration: OAuth2CapabilityConfiguration
    private var _resources: OAuth2CapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "oauth2-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: OAuth2CapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: OAuth2CapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: OAuth2CapabilityConfiguration,
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = OAuth2CapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: OAuth2CapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid OAuth2 configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // OAuth2 is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // OAuth2 doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - OAuth2 Operations
    
    /// Create authorization URL for OAuth2 flow
    public func createAuthorizationURL() async throws -> URL {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("OAuth2 capability not available")
        }
        
        return try await _resources.createAuthorizationURL()
    }
    
    /// Handle authorization response from redirect
    public func handleAuthorizationResponse(_ url: URL) async throws -> OAuth2Token {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("OAuth2 capability not available")
        }
        
        return try await _resources.handleAuthorizationResponse(url)
    }
    
    /// Authenticate using client credentials flow
    public func authenticateWithClientCredentials() async throws -> OAuth2Token {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("OAuth2 capability not available")
        }
        
        return try await _resources.authenticateWithClientCredentials()
    }
    
    /// Refresh current access token
    public func refreshToken() async throws -> OAuth2Token {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("OAuth2 capability not available")
        }
        
        return try await _resources.refreshToken()
    }
    
    /// Get user information from userinfo endpoint
    public func getUserInfo() async throws -> OAuth2UserInfo {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("OAuth2 capability not available")
        }
        
        return try await _resources.getUserInfo()
    }
    
    /// Revoke current token
    public func revokeToken() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("OAuth2 capability not available")
        }
        
        try await _resources.revokeToken()
    }
    
    /// Get current access token
    public func getCurrentToken() async -> OAuth2Token? {
        await _resources.getCurrentToken()
    }
    
    /// Check if currently authenticated
    public func isAuthenticated() async -> Bool {
        await _resources.isAuthenticated()
    }
    
    /// Check if token will expire soon
    public func willTokenExpireSoon() async -> Bool {
        await _resources.willTokenExpireSoon()
    }
    
    /// Get OAuth2 metrics
    public func getMetrics() async -> OAuth2Metrics {
        await _resources.getMetrics()
    }
    
    /// Automatic token refresh if needed
    public func ensureValidToken() async throws -> OAuth2Token {
        if await willTokenExpireSoon() {
            return try await refreshToken()
        } else if let token = await getCurrentToken() {
            return token
        } else {
            throw OAuth2Error.noAccessToken
        }
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// OAuth2 specific errors
public enum OAuth2Error: Error, LocalizedError {
    case clientNotAvailable
    case invalidAuthorizationURL
    case invalidState
    case invalidAuthorizationResponse
    case authorizationFailed(String, String?)
    case tokenRequestFailed(String, String?)
    case unsupportedGrantType(String)
    case missingClientSecret
    case noAccessToken
    case noRefreshToken
    case tokenRefreshNotEnabled
    case userInfoEndpointNotConfigured
    case revocationEndpointNotConfigured
    case discoveryFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .clientNotAvailable:
            return "OAuth2 client is not available"
        case .invalidAuthorizationURL:
            return "Failed to create valid authorization URL"
        case .invalidState:
            return "Invalid or mismatched state parameter"
        case .invalidAuthorizationResponse:
            return "Invalid authorization response"
        case .authorizationFailed(let error, let description):
            return "Authorization failed: \(error) - \(description ?? "")"
        case .tokenRequestFailed(let error, let description):
            return "Token request failed: \(error) - \(description ?? "")"
        case .unsupportedGrantType(let grantType):
            return "Unsupported grant type: \(grantType)"
        case .missingClientSecret:
            return "Client secret is required for this grant type"
        case .noAccessToken:
            return "No access token available"
        case .noRefreshToken:
            return "No refresh token available"
        case .tokenRefreshNotEnabled:
            return "Token refresh is not enabled"
        case .userInfoEndpointNotConfigured:
            return "UserInfo endpoint is not configured"
        case .revocationEndpointNotConfigured:
            return "Token revocation endpoint is not configured"
        case .discoveryFailed(let error):
            return "OAuth2 discovery failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

import CryptoKit

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}