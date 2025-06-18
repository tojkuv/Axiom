import Foundation
import CryptoKit
import AxiomCore
import AxiomCapabilities

// MARK: - JWT Capability Configuration

/// Configuration for JWT capability
public struct JWTCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let defaultIssuer: String?
    public let defaultAudience: String?
    public let defaultExpirationTime: TimeInterval
    public let clockSkewTolerance: TimeInterval
    public let enableExpirationValidation: Bool
    public let enableIssuerValidation: Bool
    public let enableAudienceValidation: Bool
    public let enableSignatureValidation: Bool
    public let enableClockSkewValidation: Bool
    public let supportedAlgorithms: Set<JWTAlgorithm>
    public let keyManagement: KeyManagementPolicy
    public let enableKeyRotation: Bool
    public let keyRotationInterval: TimeInterval
    public let enableCaching: Bool
    public let cacheTTL: TimeInterval
    public let maxCacheSize: Int
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableSecureStorage: Bool
    public let customClaimValidators: [String: String] // ClaimName -> ValidationRule
    
    public enum KeyManagementPolicy: String, Codable, CaseIterable, Sendable {
        case inMemory = "in-memory"
        case keychain = "keychain"
        case external = "external"
        case jwks = "jwks"
    }
    
    public init(
        defaultIssuer: String? = nil,
        defaultAudience: String? = nil,
        defaultExpirationTime: TimeInterval = 3600.0, // 1 hour
        clockSkewTolerance: TimeInterval = 60.0, // 1 minute
        enableExpirationValidation: Bool = true,
        enableIssuerValidation: Bool = true,
        enableAudienceValidation: Bool = true,
        enableSignatureValidation: Bool = true,
        enableClockSkewValidation: Bool = true,
        supportedAlgorithms: Set<JWTAlgorithm> = [.HS256, .RS256, .ES256],
        keyManagement: KeyManagementPolicy = .keychain,
        enableKeyRotation: Bool = false,
        keyRotationInterval: TimeInterval = 86400.0, // 24 hours
        enableCaching: Bool = true,
        cacheTTL: TimeInterval = 300.0, // 5 minutes
        maxCacheSize: Int = 100,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableSecureStorage: Bool = true,
        customClaimValidators: [String: String] = [:]
    ) {
        self.defaultIssuer = defaultIssuer
        self.defaultAudience = defaultAudience
        self.defaultExpirationTime = defaultExpirationTime
        self.clockSkewTolerance = clockSkewTolerance
        self.enableExpirationValidation = enableExpirationValidation
        self.enableIssuerValidation = enableIssuerValidation
        self.enableAudienceValidation = enableAudienceValidation
        self.enableSignatureValidation = enableSignatureValidation
        self.enableClockSkewValidation = enableClockSkewValidation
        self.supportedAlgorithms = supportedAlgorithms
        self.keyManagement = keyManagement
        self.enableKeyRotation = enableKeyRotation
        self.keyRotationInterval = keyRotationInterval
        self.enableCaching = enableCaching
        self.cacheTTL = cacheTTL
        self.maxCacheSize = maxCacheSize
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableSecureStorage = enableSecureStorage
        self.customClaimValidators = customClaimValidators
    }
    
    public var isValid: Bool {
        defaultExpirationTime > 0 &&
        clockSkewTolerance >= 0 &&
        keyRotationInterval > 0 &&
        cacheTTL > 0 &&
        maxCacheSize > 0 &&
        !supportedAlgorithms.isEmpty
    }
    
    public func merged(with other: JWTCapabilityConfiguration) -> JWTCapabilityConfiguration {
        JWTCapabilityConfiguration(
            defaultIssuer: other.defaultIssuer ?? defaultIssuer,
            defaultAudience: other.defaultAudience ?? defaultAudience,
            defaultExpirationTime: other.defaultExpirationTime,
            clockSkewTolerance: other.clockSkewTolerance,
            enableExpirationValidation: other.enableExpirationValidation,
            enableIssuerValidation: other.enableIssuerValidation,
            enableAudienceValidation: other.enableAudienceValidation,
            enableSignatureValidation: other.enableSignatureValidation,
            enableClockSkewValidation: other.enableClockSkewValidation,
            supportedAlgorithms: other.supportedAlgorithms.union(supportedAlgorithms),
            keyManagement: other.keyManagement,
            enableKeyRotation: other.enableKeyRotation,
            keyRotationInterval: other.keyRotationInterval,
            enableCaching: other.enableCaching,
            cacheTTL: other.cacheTTL,
            maxCacheSize: other.maxCacheSize,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableSecureStorage: other.enableSecureStorage,
            customClaimValidators: customClaimValidators.merging(other.customClaimValidators) { _, new in new }
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> JWTCapabilityConfiguration {
        var adjustedLogging = enableLogging
        var adjustedCaching = enableCaching
        var adjustedTolerance = clockSkewTolerance
        
        if environment.isLowPowerMode {
            adjustedCaching = true // Enable more aggressive caching
            adjustedTolerance *= 2.0 // More lenient timing
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return JWTCapabilityConfiguration(
            defaultIssuer: defaultIssuer,
            defaultAudience: defaultAudience,
            defaultExpirationTime: defaultExpirationTime,
            clockSkewTolerance: adjustedTolerance,
            enableExpirationValidation: enableExpirationValidation,
            enableIssuerValidation: enableIssuerValidation,
            enableAudienceValidation: enableAudienceValidation,
            enableSignatureValidation: enableSignatureValidation,
            enableClockSkewValidation: enableClockSkewValidation,
            supportedAlgorithms: supportedAlgorithms,
            keyManagement: keyManagement,
            enableKeyRotation: enableKeyRotation,
            keyRotationInterval: keyRotationInterval,
            enableCaching: adjustedCaching,
            cacheTTL: cacheTTL,
            maxCacheSize: maxCacheSize,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableSecureStorage: enableSecureStorage,
            customClaimValidators: customClaimValidators
        )
    }
}

// MARK: - JWT Types

/// JWT algorithm types
public enum JWTAlgorithm: String, Codable, CaseIterable, Sendable {
    case none = "none"
    case HS256 = "HS256"
    case HS384 = "HS384"
    case HS512 = "HS512"
    case RS256 = "RS256"
    case RS384 = "RS384"
    case RS512 = "RS512"
    case ES256 = "ES256"
    case ES384 = "ES384"
    case ES512 = "ES512"
    case PS256 = "PS256"
    case PS384 = "PS384"
    case PS512 = "PS512"
    
    public var family: AlgorithmFamily {
        switch self {
        case .none:
            return .none
        case .HS256, .HS384, .HS512:
            return .hmac
        case .RS256, .RS384, .RS512:
            return .rsa
        case .ES256, .ES384, .ES512:
            return .ecdsa
        case .PS256, .PS384, .PS512:
            return .rsaPSS
        }
    }
    
    public enum AlgorithmFamily: String, Codable, CaseIterable, Sendable {
        case none = "none"
        case hmac = "HMAC"
        case rsa = "RSA"
        case ecdsa = "ECDSA"
        case rsaPSS = "RSA-PSS"
    }
}

/// JWT header
public struct JWTHeader: Codable, Sendable {
    public let alg: JWTAlgorithm
    public let typ: String?
    public let kid: String?
    public let cty: String?
    public let crit: [String]?
    public let additionalFields: [String: AnyCodable]?
    
    public init(
        alg: JWTAlgorithm,
        typ: String? = "JWT",
        kid: String? = nil,
        cty: String? = nil,
        crit: [String]? = nil,
        additionalFields: [String: AnyCodable]? = nil
    ) {
        self.alg = alg
        self.typ = typ
        self.kid = kid
        self.cty = cty
        self.crit = crit
        self.additionalFields = additionalFields
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        
        alg = try container.decode(JWTAlgorithm.self, forKey: DynamicCodingKeys(stringValue: "alg")!)
        typ = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "typ")!)
        kid = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "kid")!)
        cty = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "cty")!)
        crit = try container.decodeIfPresent([String].self, forKey: DynamicCodingKeys(stringValue: "crit")!)
        
        // Parse additional fields
        var additional: [String: AnyCodable] = [:]
        let standardKeys = Set(["alg", "typ", "kid", "cty", "crit"])
        
        for key in container.allKeys {
            if !standardKeys.contains(key.stringValue) {
                additional[key.stringValue] = try container.decode(AnyCodable.self, forKey: key)
            }
        }
        
        additionalFields = additional.isEmpty ? nil : additional
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        
        try container.encode(alg, forKey: DynamicCodingKeys(stringValue: "alg")!)
        try container.encodeIfPresent(typ, forKey: DynamicCodingKeys(stringValue: "typ")!)
        try container.encodeIfPresent(kid, forKey: DynamicCodingKeys(stringValue: "kid")!)
        try container.encodeIfPresent(cty, forKey: DynamicCodingKeys(stringValue: "cty")!)
        try container.encodeIfPresent(crit, forKey: DynamicCodingKeys(stringValue: "crit")!)
        
        if let additionalFields = additionalFields {
            for (key, value) in additionalFields {
                try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
            }
        }
    }
}

/// JWT payload (claims)
public struct JWTPayload: Codable, Sendable {
    // Standard claims
    public let iss: String?          // Issuer
    public let sub: String?          // Subject
    public let aud: [String]?        // Audience
    public let exp: Date?            // Expiration Time
    public let iat: Date?            // Issued At
    public let nbf: Date?            // Not Before
    public let jti: String?          // JWT ID
    
    // Custom claims
    public let customClaims: [String: AnyCodable]?
    
    public init(
        iss: String? = nil,
        sub: String? = nil,
        aud: [String]? = nil,
        exp: Date? = nil,
        iat: Date? = nil,
        nbf: Date? = nil,
        jti: String? = nil,
        customClaims: [String: AnyCodable]? = nil
    ) {
        self.iss = iss
        self.sub = sub
        self.aud = aud
        self.exp = exp
        self.iat = iat
        self.nbf = nbf
        self.jti = jti
        self.customClaims = customClaims
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        
        iss = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "iss")!)
        sub = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "sub")!)
        
        // Handle audience - can be string or array of strings
        if let audString = try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "aud")!) {
            aud = [audString]
        } else {
            aud = try container.decodeIfPresent([String].self, forKey: DynamicCodingKeys(stringValue: "aud")!)
        }
        
        // Handle date fields (Unix timestamps)
        if let expTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: DynamicCodingKeys(stringValue: "exp")!) {
            exp = Date(timeIntervalSince1970: expTimestamp)
        } else {
            exp = nil
        }
        
        if let iatTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: DynamicCodingKeys(stringValue: "iat")!) {
            iat = Date(timeIntervalSince1970: iatTimestamp)
        } else {
            iat = nil
        }
        
        if let nbfTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: DynamicCodingKeys(stringValue: "nbf")!) {
            nbf = Date(timeIntervalSince1970: nbfTimestamp)
        } else {
            nbf = nil
        }
        
        jti = try container.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "jti")!)
        
        // Parse custom claims
        var custom: [String: AnyCodable] = [:]
        let standardKeys = Set(["iss", "sub", "aud", "exp", "iat", "nbf", "jti"])
        
        for key in container.allKeys {
            if !standardKeys.contains(key.stringValue) {
                custom[key.stringValue] = try container.decode(AnyCodable.self, forKey: key)
            }
        }
        
        customClaims = custom.isEmpty ? nil : custom
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        
        try container.encodeIfPresent(iss, forKey: DynamicCodingKeys(stringValue: "iss")!)
        try container.encodeIfPresent(sub, forKey: DynamicCodingKeys(stringValue: "sub")!)
        try container.encodeIfPresent(aud, forKey: DynamicCodingKeys(stringValue: "aud")!)
        try container.encodeIfPresent(exp?.timeIntervalSince1970, forKey: DynamicCodingKeys(stringValue: "exp")!)
        try container.encodeIfPresent(iat?.timeIntervalSince1970, forKey: DynamicCodingKeys(stringValue: "iat")!)
        try container.encodeIfPresent(nbf?.timeIntervalSince1970, forKey: DynamicCodingKeys(stringValue: "nbf")!)
        try container.encodeIfPresent(jti, forKey: DynamicCodingKeys(stringValue: "jti")!)
        
        if let customClaims = customClaims {
            for (key, value) in customClaims {
                try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
            }
        }
    }
    
    public var isExpired: Bool {
        guard let exp = exp else { return false }
        return Date() >= exp
    }
    
    public var isValid: Bool {
        let now = Date()
        
        // Check expiration
        if let exp = exp, now >= exp {
            return false
        }
        
        // Check not before
        if let nbf = nbf, now < nbf {
            return false
        }
        
        return true
    }
}

/// JWT token structure
public struct JWT: Sendable {
    public let header: JWTHeader
    public let payload: JWTPayload
    public let signature: Data
    public let rawToken: String
    
    public init(header: JWTHeader, payload: JWTPayload, signature: Data, rawToken: String) {
        self.header = header
        self.payload = payload
        self.signature = signature
        self.rawToken = rawToken
    }
    
    public var isExpired: Bool {
        payload.isExpired
    }
    
    public var isValid: Bool {
        payload.isValid
    }
}

/// JWT key information
public struct JWTKey: Sendable {
    public let keyId: String?
    public let keyType: KeyType
    public let algorithm: JWTAlgorithm
    public let keyData: Data
    public let publicKey: Data?
    public let createdAt: Date
    public let expiresAt: Date?
    
    public enum KeyType: String, Codable, CaseIterable, Sendable {
        case symmetric = "symmetric"
        case rsa = "RSA"
        case ec = "EC"
        case oct = "oct"
    }
    
    public init(
        keyId: String? = nil,
        keyType: KeyType,
        algorithm: JWTAlgorithm,
        keyData: Data,
        publicKey: Data? = nil,
        createdAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.keyId = keyId
        self.keyType = keyType
        self.algorithm = algorithm
        self.keyData = keyData
        self.publicKey = publicKey
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
    
    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() >= expiresAt
    }
}

/// JWT validation result
public struct JWTValidationResult: Sendable {
    public let isValid: Bool
    public let validatedClaims: Set<String>
    public let failedValidations: [ValidationFailure]
    public let validatedAt: Date
    
    public struct ValidationFailure: Sendable {
        public let type: ValidationType
        public let message: String
        public let claimName: String?
        
        public init(type: ValidationType, message: String, claimName: String? = nil) {
            self.type = type
            self.message = message
            self.claimName = claimName
        }
    }
    
    public enum ValidationType: String, Codable, CaseIterable, Sendable {
        case signature = "signature"
        case expiration = "expiration"
        case notBefore = "not_before"
        case issuer = "issuer"
        case audience = "audience"
        case customClaim = "custom_claim"
        case algorithm = "algorithm"
    }
    
    public init(
        isValid: Bool,
        validatedClaims: Set<String> = [],
        failedValidations: [ValidationFailure] = [],
        validatedAt: Date = Date()
    ) {
        self.isValid = isValid
        self.validatedClaims = validatedClaims
        self.failedValidations = failedValidations
        self.validatedAt = validatedAt
    }
}

/// JWT metrics
public struct JWTMetrics: Sendable {
    public let tokensCreated: Int
    public let tokensValidated: Int
    public let validTokens: Int
    public let invalidTokens: Int
    public let expiredTokens: Int
    public let signatureFailures: Int
    public let cacheHits: Int
    public let cacheMisses: Int
    public let averageValidationTime: TimeInterval
    public let averageCreationTime: TimeInterval
    
    public init(
        tokensCreated: Int = 0,
        tokensValidated: Int = 0,
        validTokens: Int = 0,
        invalidTokens: Int = 0,
        expiredTokens: Int = 0,
        signatureFailures: Int = 0,
        cacheHits: Int = 0,
        cacheMisses: Int = 0,
        averageValidationTime: TimeInterval = 0,
        averageCreationTime: TimeInterval = 0
    ) {
        self.tokensCreated = tokensCreated
        self.tokensValidated = tokensValidated
        self.validTokens = validTokens
        self.invalidTokens = invalidTokens
        self.expiredTokens = expiredTokens
        self.signatureFailures = signatureFailures
        self.cacheHits = cacheHits
        self.cacheMisses = cacheMisses
        self.averageValidationTime = averageValidationTime
        self.averageCreationTime = averageCreationTime
    }
    
    public var validationSuccessRate: Double {
        guard tokensValidated > 0 else { return 0.0 }
        return Double(validTokens) / Double(tokensValidated)
    }
    
    public var cacheHitRate: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0.0 }
        return Double(cacheHits) / Double(total)
    }
}

// MARK: - Dynamic Coding Keys

internal struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - JWT Resource

/// JWT resource management
public actor JWTCapabilityResource: AxiomCapabilityResource {
    private let configuration: JWTCapabilityConfiguration
    private var keychainCapability: KeychainCapability?
    private var keys: [String: JWTKey] = [:]
    private var validationCache: [String: (result: JWTValidationResult, timestamp: Date)] = [:]
    private var metrics: JWTMetrics = JWTMetrics()
    private var validationTimes: [TimeInterval] = []
    private var creationTimes: [TimeInterval] = []
    
    public init(configuration: JWTCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: configuration.maxCacheSize * 10_000, // 10KB per cache entry
            cpu: 10.0, // 10% CPU for JWT operations
            bandwidth: 0, // No network bandwidth for JWT operations
            storage: configuration.enableSecureStorage ? 1_000_000 : 0 // 1MB for key storage
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let cacheSize = validationCache.count * 5_000 // Rough estimate
            let keySize = keys.count * 1_000
            
            return ResourceUsage(
                memory: cacheSize + keySize,
                cpu: 5.0,
                bandwidth: 0,
                storage: configuration.enableSecureStorage ? keySize : 0
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        true // JWT operations are always available
    }
    
    public func release() async {
        await keychainCapability?.deactivate()
        keychainCapability = nil
        keys.removeAll()
        validationCache.removeAll()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Create Keychain capability for secure key storage if enabled
        if configuration.enableSecureStorage && configuration.keyManagement == .keychain {
            let keychainConfig = KeychainCapabilityConfiguration(
                service: "com.axiom.jwt",
                enableLogging: configuration.enableLogging
            )
            
            keychainCapability = KeychainCapability(configuration: keychainConfig)
            try await keychainCapability?.activate()
            
            // Load existing keys from keychain
            await loadKeysFromKeychain()
        }
    }
    
    internal func updateConfiguration(_ configuration: JWTCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - JWT Operations
    
    public func parseToken(_ tokenString: String) throws -> JWT {
        let components = tokenString.components(separatedBy: ".")
        guard components.count == 3 else {
            throw JWTError.invalidTokenFormat
        }
        
        // Decode header
        guard let headerData = Data(base64URLEncoded: components[0]) else {
            throw JWTError.invalidHeader
        }
        let header = try JSONDecoder().decode(JWTHeader.self, from: headerData)
        
        // Decode payload
        guard let payloadData = Data(base64URLEncoded: components[1]) else {
            throw JWTError.invalidPayload
        }
        let payload = try JSONDecoder().decode(JWTPayload.self, from: payloadData)
        
        // Decode signature
        guard let signature = Data(base64URLEncoded: components[2]) else {
            throw JWTError.invalidSignature
        }
        
        return JWT(header: header, payload: payload, signature: signature, rawToken: tokenString)
    }
    
    public func createToken(
        header: JWTHeader,
        payload: JWTPayload,
        key: JWTKey
    ) async throws -> String {
        let startTime = Date()
        
        // Validate algorithm compatibility
        guard header.alg == key.algorithm else {
            throw JWTError.algorithmMismatch
        }
        
        // Encode header
        let headerData = try JSONEncoder().encode(header)
        let headerString = headerData.base64URLEncodedString()
        
        // Encode payload
        let payloadData = try JSONEncoder().encode(payload)
        let payloadString = payloadData.base64URLEncodedString()
        
        // Create signing input
        let signingInput = "\(headerString).\(payloadString)"
        let signingData = signingInput.data(using: .utf8)!
        
        // Generate signature
        let signature = try generateSignature(data: signingData, key: key, algorithm: header.alg)
        let signatureString = signature.base64URLEncodedString()
        
        // Combine into JWT
        let token = "\(signingInput).\(signatureString)"
        
        let duration = Date().timeIntervalSince(startTime)
        await updateCreationMetrics(duration: duration)
        
        return token
    }
    
    public func validateToken(
        _ tokenString: String,
        issuer: String? = nil,
        audience: String? = nil,
        key: JWTKey? = nil
    ) async throws -> JWTValidationResult {
        let startTime = Date()
        
        // Check cache first
        if configuration.enableCaching {
            let cacheKey = "\(tokenString):\(issuer ?? ""):\(audience ?? "")"
            if let cached = validationCache[cacheKey] {
                let age = Date().timeIntervalSince(cached.timestamp)
                if age < configuration.cacheTTL {
                    await updateValidationMetrics(duration: Date().timeIntervalSince(startTime), fromCache: true, valid: cached.result.isValid)
                    return cached.result
                } else {
                    validationCache.removeValue(forKey: cacheKey)
                }
            }
        }
        
        // Parse token
        let jwt = try parseToken(tokenString)
        
        var validatedClaims: Set<String> = []
        var failures: [JWTValidationResult.ValidationFailure] = []
        
        // Validate algorithm
        if !configuration.supportedAlgorithms.contains(jwt.header.alg) {
            failures.append(JWTValidationResult.ValidationFailure(
                type: .algorithm,
                message: "Unsupported algorithm: \(jwt.header.alg.rawValue)"
            ))
        }
        
        // Validate signature if enabled and key provided
        if configuration.enableSignatureValidation, let key = key {
            do {
                let isSignatureValid = try await verifySignature(jwt: jwt, key: key)
                if isSignatureValid {
                    validatedClaims.insert("signature")
                } else {
                    failures.append(JWTValidationResult.ValidationFailure(
                        type: .signature,
                        message: "Invalid signature"
                    ))
                }
            } catch {
                failures.append(JWTValidationResult.ValidationFailure(
                    type: .signature,
                    message: "Signature verification failed: \(error.localizedDescription)"
                ))
            }
        }
        
        // Validate expiration
        if configuration.enableExpirationValidation {
            if let exp = jwt.payload.exp {
                let tolerance = configuration.enableClockSkewValidation ? configuration.clockSkewTolerance : 0
                if Date().addingTimeInterval(-tolerance) >= exp {
                    failures.append(JWTValidationResult.ValidationFailure(
                        type: .expiration,
                        message: "Token has expired",
                        claimName: "exp"
                    ))
                } else {
                    validatedClaims.insert("exp")
                }
            }
        }
        
        // Validate not before
        if let nbf = jwt.payload.nbf {
            let tolerance = configuration.enableClockSkewValidation ? configuration.clockSkewTolerance : 0
            if Date().addingTimeInterval(tolerance) < nbf {
                failures.append(JWTValidationResult.ValidationFailure(
                    type: .notBefore,
                    message: "Token is not yet valid",
                    claimName: "nbf"
                ))
            } else {
                validatedClaims.insert("nbf")
            }
        }
        
        // Validate issuer
        if configuration.enableIssuerValidation {
            let expectedIssuer = issuer ?? configuration.defaultIssuer
            if let expectedIssuer = expectedIssuer {
                if jwt.payload.iss == expectedIssuer {
                    validatedClaims.insert("iss")
                } else {
                    failures.append(JWTValidationResult.ValidationFailure(
                        type: .issuer,
                        message: "Invalid issuer. Expected: \(expectedIssuer), Got: \(jwt.payload.iss ?? "nil")",
                        claimName: "iss"
                    ))
                }
            }
        }
        
        // Validate audience
        if configuration.enableAudienceValidation {
            let expectedAudience = audience ?? configuration.defaultAudience
            if let expectedAudience = expectedAudience {
                if let tokenAudience = jwt.payload.aud, tokenAudience.contains(expectedAudience) {
                    validatedClaims.insert("aud")
                } else {
                    failures.append(JWTValidationResult.ValidationFailure(
                        type: .audience,
                        message: "Invalid audience. Expected: \(expectedAudience), Got: \(jwt.payload.aud?.joined(separator: ", ") ?? "nil")",
                        claimName: "aud"
                    ))
                }
            }
        }
        
        // Validate custom claims
        if let customClaims = jwt.payload.customClaims {
            for (claimName, validator) in configuration.customClaimValidators {
                if let claimValue = customClaims[claimName] {
                    // Simple validation (could be extended with more complex rules)
                    if validateCustomClaim(claimValue, against: validator) {
                        validatedClaims.insert(claimName)
                    } else {
                        failures.append(JWTValidationResult.ValidationFailure(
                            type: .customClaim,
                            message: "Custom claim validation failed",
                            claimName: claimName
                        ))
                    }
                }
            }
        }
        
        let result = JWTValidationResult(
            isValid: failures.isEmpty,
            validatedClaims: validatedClaims,
            failedValidations: failures
        )
        
        // Cache result
        if configuration.enableCaching {
            let cacheKey = "\(tokenString):\(issuer ?? ""):\(audience ?? "")"
            validationCache[cacheKey] = (result: result, timestamp: Date())
            
            // Simple cache cleanup
            if validationCache.count > configuration.maxCacheSize {
                let oldestKey = validationCache.min { $0.value.timestamp < $1.value.timestamp }?.key
                if let key = oldestKey {
                    validationCache.removeValue(forKey: key)
                }
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        await updateValidationMetrics(duration: duration, fromCache: false, valid: result.isValid)
        
        return result
    }
    
    public func addKey(_ key: JWTKey) async throws {
        let keyId = key.keyId ?? UUID().uuidString
        keys[keyId] = key
        
        if configuration.enableSecureStorage && configuration.keyManagement == .keychain {
            await saveKeyToKeychain(key, keyId: keyId)
        }
    }
    
    public func getKey(keyId: String) -> JWTKey? {
        keys[keyId]
    }
    
    public func removeKey(keyId: String) async {
        keys.removeValue(forKey: keyId)
        
        if configuration.enableSecureStorage && configuration.keyManagement == .keychain {
            await removeKeyFromKeychain(keyId: keyId)
        }
    }
    
    public func getAllKeys() -> [JWTKey] {
        Array(keys.values)
    }
    
    public func getMetrics() -> JWTMetrics {
        metrics
    }
    
    public func clearCache() {
        validationCache.removeAll()
    }
    
    // MARK: - Private Implementation
    
    private func generateSignature(data: Data, key: JWTKey, algorithm: JWTAlgorithm) throws -> Data {
        switch algorithm.family {
        case .none:
            return Data()
            
        case .hmac:
            return try generateHMACSignature(data: data, key: key, algorithm: algorithm)
            
        case .rsa, .rsaPSS:
            return try generateRSASignature(data: data, key: key, algorithm: algorithm)
            
        case .ecdsa:
            return try generateECDSASignature(data: data, key: key, algorithm: algorithm)
        }
    }
    
    private func generateHMACSignature(data: Data, key: JWTKey, algorithm: JWTAlgorithm) throws -> Data {
        let symmetricKey = SymmetricKey(data: key.keyData)
        
        switch algorithm {
        case .HS256:
            let authentication = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
            return Data(authentication)
        case .HS384:
            let authentication = HMAC<SHA384>.authenticationCode(for: data, using: symmetricKey)
            return Data(authentication)
        case .HS512:
            let authentication = HMAC<SHA512>.authenticationCode(for: data, using: symmetricKey)
            return Data(authentication)
        default:
            throw JWTError.unsupportedAlgorithm(algorithm.rawValue)
        }
    }
    
    private func generateRSASignature(data: Data, key: JWTKey, algorithm: JWTAlgorithm) throws -> Data {
        // RSA signature implementation would go here
        // This is a simplified placeholder
        throw JWTError.unsupportedAlgorithm(algorithm.rawValue)
    }
    
    private func generateECDSASignature(data: Data, key: JWTKey, algorithm: JWTAlgorithm) throws -> Data {
        // ECDSA signature implementation would go here
        // This is a simplified placeholder
        throw JWTError.unsupportedAlgorithm(algorithm.rawValue)
    }
    
    private func verifySignature(jwt: JWT, key: JWTKey) async throws -> Bool {
        let components = jwt.rawToken.components(separatedBy: ".")
        guard components.count == 3 else { return false }
        
        let signingInput = "\(components[0]).\(components[1])"
        let signingData = signingInput.data(using: .utf8)!
        
        switch jwt.header.alg.family {
        case .none:
            return jwt.signature.isEmpty
            
        case .hmac:
            let expectedSignature = try generateHMACSignature(data: signingData, key: key, algorithm: jwt.header.alg)
            return expectedSignature == jwt.signature
            
        case .rsa, .rsaPSS:
            // RSA verification would go here
            return false
            
        case .ecdsa:
            // ECDSA verification would go here
            return false
        }
    }
    
    private func validateCustomClaim(_ claimValue: AnyCodable, against validator: String) -> Bool {
        // Simple validation - could be extended with more complex rules
        // For now, just check if the value exists
        return true
    }
    
    private func saveKeyToKeychain(_ key: JWTKey, keyId: String) async {
        guard let keychain = keychainCapability else { return }
        
        do {
            let keyData = try JSONEncoder().encode(key)
            let keychainKey = "jwt_key_\(keyId)"
            try await keychain.store(key: keychainKey, data: keyData)
        } catch {
            if configuration.enableLogging {
                print("[JWT] Failed to save key to keychain: \(error)")
            }
        }
    }
    
    private func loadKeysFromKeychain() async {
        guard let keychain = keychainCapability else { return }
        
        // This would typically involve loading all keys with a prefix
        // For simplicity, we'll skip the implementation
    }
    
    private func removeKeyFromKeychain(keyId: String) async {
        guard let keychain = keychainCapability else { return }
        
        do {
            let keychainKey = "jwt_key_\(keyId)"
            try await keychain.delete(key: keychainKey)
        } catch {
            // Error removing is fine
        }
    }
    
    private func updateValidationMetrics(duration: TimeInterval, fromCache: Bool, valid: Bool) async {
        validationTimes.append(duration)
        
        let averageValidation = validationTimes.reduce(0, +) / Double(validationTimes.count)
        
        metrics = JWTMetrics(
            tokensCreated: metrics.tokensCreated,
            tokensValidated: metrics.tokensValidated + 1,
            validTokens: valid ? metrics.validTokens + 1 : metrics.validTokens,
            invalidTokens: valid ? metrics.invalidTokens : metrics.invalidTokens + 1,
            expiredTokens: metrics.expiredTokens,
            signatureFailures: metrics.signatureFailures,
            cacheHits: fromCache ? metrics.cacheHits + 1 : metrics.cacheHits,
            cacheMisses: fromCache ? metrics.cacheMisses : metrics.cacheMisses + 1,
            averageValidationTime: averageValidation,
            averageCreationTime: metrics.averageCreationTime
        )
    }
    
    private func updateCreationMetrics(duration: TimeInterval) async {
        creationTimes.append(duration)
        
        let averageCreation = creationTimes.reduce(0, +) / Double(creationTimes.count)
        
        metrics = JWTMetrics(
            tokensCreated: metrics.tokensCreated + 1,
            tokensValidated: metrics.tokensValidated,
            validTokens: metrics.validTokens,
            invalidTokens: metrics.invalidTokens,
            expiredTokens: metrics.expiredTokens,
            signatureFailures: metrics.signatureFailures,
            cacheHits: metrics.cacheHits,
            cacheMisses: metrics.cacheMisses,
            averageValidationTime: metrics.averageValidationTime,
            averageCreationTime: averageCreation
        )
    }
}

// MARK: - JWT Capability Implementation

/// JWT capability providing JSON Web Token handling
public actor JWTCapability: DomainCapability {
    public typealias ConfigurationType = JWTCapabilityConfiguration
    public typealias ResourceType = JWTCapabilityResource
    
    private var _configuration: JWTCapabilityConfiguration
    private var _resources: JWTCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "jwt-capability" }
    
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
    
    public var configuration: JWTCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: JWTCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: JWTCapabilityConfiguration = JWTCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = JWTCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: JWTCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid JWT configuration")
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
        // JWT is supported on all platforms
        true
    }
    
    public func requestPermission() async throws {
        // JWT doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - JWT Operations
    
    /// Parse JWT token string
    public func parseToken(_ tokenString: String) async throws -> JWT {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JWT capability not available")
        }
        
        return try await _resources.parseToken(tokenString)
    }
    
    /// Create JWT token
    public func createToken(
        header: JWTHeader,
        payload: JWTPayload,
        key: JWTKey
    ) async throws -> String {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JWT capability not available")
        }
        
        return try await _resources.createToken(header: header, payload: payload, key: key)
    }
    
    /// Validate JWT token
    public func validateToken(
        _ tokenString: String,
        issuer: String? = nil,
        audience: String? = nil,
        key: JWTKey? = nil
    ) async throws -> JWTValidationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JWT capability not available")
        }
        
        return try await _resources.validateToken(tokenString, issuer: issuer, audience: audience, key: key)
    }
    
    /// Add signing/verification key
    public func addKey(_ key: JWTKey) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JWT capability not available")
        }
        
        try await _resources.addKey(key)
    }
    
    /// Get key by ID
    public func getKey(keyId: String) async -> JWTKey? {
        await _resources.getKey(keyId: keyId)
    }
    
    /// Remove key
    public func removeKey(keyId: String) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("JWT capability not available")
        }
        
        await _resources.removeKey(keyId: keyId)
    }
    
    /// Get all keys
    public func getAllKeys() async -> [JWTKey] {
        await _resources.getAllKeys()
    }
    
    /// Get JWT metrics
    public func getMetrics() async -> JWTMetrics {
        await _resources.getMetrics()
    }
    
    /// Clear validation cache
    public func clearCache() async {
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create simple HMAC-signed token
    public func createHMACToken(
        subject: String,
        issuer: String? = nil,
        audience: String? = nil,
        expirationTime: TimeInterval? = nil,
        customClaims: [String: AnyCodable]? = nil,
        secret: Data
    ) async throws -> String {
        let header = JWTHeader(alg: .HS256)
        
        let exp = expirationTime.map { Date().addingTimeInterval($0) }
        let payload = JWTPayload(
            iss: issuer ?? _configuration.defaultIssuer,
            sub: subject,
            aud: audience.map { [$0] } ?? _configuration.defaultAudience.map { [$0] },
            exp: exp,
            iat: Date(),
            jti: UUID().uuidString,
            customClaims: customClaims
        )
        
        let key = JWTKey(
            keyType: .symmetric,
            algorithm: .HS256,
            keyData: secret
        )
        
        return try await createToken(header: header, payload: payload, key: key)
    }
    
    /// Validate token and extract payload
    public func validateAndExtractPayload(
        _ tokenString: String,
        issuer: String? = nil,
        audience: String? = nil,
        key: JWTKey? = nil
    ) async throws -> JWTPayload {
        let jwt = try await parseToken(tokenString)
        let validationResult = try await validateToken(tokenString, issuer: issuer, audience: audience, key: key)
        
        guard validationResult.isValid else {
            throw JWTError.validationFailed(validationResult.failedValidations.map { $0.message }.joined(separator: ", "))
        }
        
        return jwt.payload
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// JWT specific errors
public enum JWTError: Error, LocalizedError {
    case invalidTokenFormat
    case invalidHeader
    case invalidPayload
    case invalidSignature
    case algorithmMismatch
    case unsupportedAlgorithm(String)
    case keyNotFound(String)
    case validationFailed(String)
    case signingFailed(Error)
    case parsingFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidTokenFormat:
            return "Invalid JWT token format"
        case .invalidHeader:
            return "Invalid JWT header"
        case .invalidPayload:
            return "Invalid JWT payload"
        case .invalidSignature:
            return "Invalid JWT signature"
        case .algorithmMismatch:
            return "Algorithm mismatch between header and key"
        case .unsupportedAlgorithm(let algorithm):
            return "Unsupported algorithm: \(algorithm)"
        case .keyNotFound(let keyId):
            return "Key not found: \(keyId)"
        case .validationFailed(let message):
            return "JWT validation failed: \(message)"
        case .signingFailed(let error):
            return "JWT signing failed: \(error.localizedDescription)"
        case .parsingFailed(let error):
            return "JWT parsing failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension Data {
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        self.init(base64Encoded: base64)
    }
    
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}